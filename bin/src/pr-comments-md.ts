#!/usr/bin/env bun

import { $ } from "bun";

/**
 * pr-comments-md
 *
 * Goal:
 * Export selected unresolved GitHub PR review threads as clean Markdown so
 * they can be pasted directly into an AI workflow for targeted fixes.
 *
 * What it does:
 * 1) Parses a PR URL to get owner/repo and PR number.
 * 2) Fetches unresolved, file-anchored review threads via `gh api graphql`.
 * 3) Presents one row per thread in an interactive `fzf --multi` list
 *    using the root comment first sentence as preview.
 * 4) Prints selected threads to stdout in Markdown with:
 *    thread metadata and all comments (author, timestamp, URL, and body).
 *
 * Usage:
 *   pr-comments-md https://github.com/<owner>/<repo>/pull/<number>
 *
 * Dependencies:
 *   - bun
 *   - gh (authenticated)
 *   - fzf
 */

type ThreadComment = {
  id: string;
  fullDatabaseId: number | null;
  bodyText: string;
  createdAt: string;
  url: string;
  author: { login: string } | null;
};

type ReviewThread = {
  id: string;
  isResolved: boolean;
  isOutdated: boolean;
  path: string;
  line: number | null;
  originalLine: number | null;
  comments: { nodes: ThreadComment[] };
};

type GraphQlResponse = {
  data?: {
    repository?: {
      pullRequest?: {
        reviewThreads?: {
          pageInfo?: {
            hasNextPage?: boolean;
            endCursor?: string | null;
          };
          nodes?: ReviewThread[];
        };
      };
    };
  };
  errors?: Array<{ message?: string }>;
};

type SelectableThread = {
  idx: number;
  path: string;
  lineDisplay: string;
  threadId: string;
  isOutdated: boolean;
  comments: ThreadComment[];
  rootPreview: string;
};

const REVIEW_THREADS_QUERY = `
query(
  $owner: String!
  $name: String!
  $number: Int!
  $cursor: String
) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first: 100) {
            nodes {
              id
              fullDatabaseId
              bodyText
              createdAt
              url
              author {
                login
              }
            }
          }
        }
      }
    }
  }
}
`;

function usage(): void {
  console.error("Usage: pr-comments-md <https://github.com/<owner>/<repo>/pull/<number>>");
}

function fail(message: string, code = 1): never {
  console.error(`error: ${message}`);
  process.exit(code);
}

function toText(value: string | Uint8Array): string {
  if (typeof value === "string") return value;
  return new TextDecoder().decode(value);
}

async function checkDependency(command: string): Promise<void> {
  const result = await $`command -v ${command}`.quiet().nothrow();
  if (result.exitCode !== 0) {
    fail(`required dependency not found: ${command}`);
  }
}

function parsePrUrl(raw: string): { owner: string; repo: string; number: number; normalizedUrl: string } {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    fail("invalid URL");
  }

  if (url.hostname !== "github.com") {
    fail("URL must be a github.com pull request URL");
  }

  const match = url.pathname.match(/^\/([^/]+)\/([^/]+)\/pull\/(\d+)(?:\/.*)?$/);
  if (!match) {
    fail("URL must match /<owner>/<repo>/pull/<number>");
  }

  const owner = match[1]!;
  const repo = match[2]!;
  const numberRaw = match[3]!;
  const number = Number(numberRaw);
  if (!Number.isInteger(number) || number <= 0) {
    fail("pull request number must be a positive integer");
  }

  return {
    owner,
    repo,
    number,
    normalizedUrl: `https://github.com/${owner}/${repo}/pull/${number}`,
  };
}

async function runGhApi(query: string, vars: Record<string, string | number | null>): Promise<GraphQlResponse> {
  const args = ["api", "graphql", "--field", `query=${query}`];
  for (const [key, value] of Object.entries(vars)) {
    if (value === null) continue;
    args.push("--field", `${key}=${String(value)}`);
  }

  const result = await $`gh ${args}`.quiet().nothrow();

  if (result.exitCode !== 0) {
    const stderr = toText(result.stderr).trim();
    fail(stderr || "gh api graphql failed");
  }

  try {
    return JSON.parse(toText(result.stdout)) as GraphQlResponse;
  } catch {
    fail("failed to parse gh api response as JSON");
  }
}

function toFirstSentence(text: string): string {
  const oneLine = text.replace(/\s+/g, " ").trim();
  if (!oneLine) return "(empty comment)";

  const sentence = oneLine.match(/^(.+?[.!?])(?:\s|$)/)?.[1] ?? oneLine;
  const max = 140;
  return sentence.length > max ? `${sentence.slice(0, max - 1)}…` : sentence;
}

function lineDisplay(thread: ReviewThread): string {
  if (thread.line !== null) return String(thread.line);
  if (thread.originalLine !== null) return `original ${thread.originalLine}`;
  return "unknown";
}

async function fetchAllReviewThreads(owner: string, repo: string, number: number): Promise<ReviewThread[]> {
  const allThreads: ReviewThread[] = [];
  let hasNextPage = true;
  let cursor: string | null = null;

  while (hasNextPage) {
    const response = await runGhApi(REVIEW_THREADS_QUERY, {
      owner,
      name: repo,
      number,
      cursor,
    });

    if (response.errors?.length) {
      const msg = response.errors.map((e) => e.message).filter(Boolean).join("; ");
      fail(msg || "GraphQL query failed");
    }

    const pullRequest = response.data?.repository?.pullRequest;
    if (!pullRequest) {
      fail(`pull request not found: ${owner}/${repo}#${number}`);
    }

    const page = pullRequest.reviewThreads;
    const nodes = page?.nodes ?? [];
    allThreads.push(...nodes);

    hasNextPage = Boolean(page?.pageInfo?.hasNextPage);
    cursor = page?.pageInfo?.endCursor ?? null;

    if (hasNextPage && !cursor) {
      fail("pagination cursor missing from GitHub response");
    }
  }

  return allThreads;
}

function gatherSelectableThreads(threads: ReviewThread[]): SelectableThread[] {
  const selectable: SelectableThread[] = [];
  let idx = 1;

  for (const thread of threads) {
    if (thread.isResolved) continue;
    if (!thread.path) continue;
    if (thread.line === null && thread.originalLine === null) continue;
    if (!thread.comments.nodes.length) continue;

    const comments = [...thread.comments.nodes].sort((a, b) => Date.parse(a.createdAt) - Date.parse(b.createdAt));
    const rootPreview = toFirstSentence(comments[0]?.bodyText ?? "");

    selectable.push({
      idx,
      path: thread.path,
      lineDisplay: lineDisplay(thread),
      threadId: thread.id,
      isOutdated: thread.isOutdated,
      comments,
      rootPreview,
    });
    idx += 1;
  }

  return selectable;
}

async function selectThreadsInteractive(items: SelectableThread[]): Promise<SelectableThread[]> {
  const lines = items.map((item) => {
    const outdated = item.isOutdated ? " [outdated]" : "";
    return `${item.idx}\t${item.path}:${item.lineDisplay}${outdated} | ${item.rootPreview}`;
  });

  const input = `${lines.join("\n")}\n`;
  const result = await $`printf '%s' ${input} | fzf --multi --with-nth=2.. --delimiter='\t' --prompt='Select comments (Tab toggle, Enter confirm) > ' --header='Tab: toggle  Enter: confirm'`
    .quiet()
    .nothrow();

  // fzf returns 130 when aborted (e.g., Esc/Ctrl-C). Treat as no selection.
  if (result.exitCode !== 0) {
    fail("no threads selected");
  }

  const selected = toText(result.stdout).trim();
  if (!selected) {
    fail("no threads selected");
  }

  const selectedIdx = new Set(
    selected
      .split("\n")
      .map((line) => Number(line.split("\t", 1)[0]))
      .filter((n) => Number.isInteger(n) && n > 0),
  );

  return items.filter((item) => selectedIdx.has(item.idx));
}

function formatMarkdown(selected: SelectableThread[], prNumber: number, repo: string, prUrl: string): string {
  const out: string[] = [];
  out.push(`# PR ${prNumber} of ${repo}`);
  out.push("");
  out.push(`Source: ${prUrl}`);
  out.push("");

  for (const thread of selected) {
    out.push(`Thread ID #${thread.threadId}`);
    if (thread.isOutdated) {
      out.push("Status: outdated");
    }
    out.push(`File: ${thread.path}`);
    out.push(`Line: ${thread.lineDisplay}`);
    out.push("");

    for (const [index, comment] of thread.comments.entries()) {
      const id = comment.fullDatabaseId !== null ? comment.fullDatabaseId : comment.id;
      const author = comment.author?.login ?? "unknown";
      out.push(`Comment ${index + 1} ID #${id}`);
      out.push(`Author: @${author}`);
      out.push(`Created: ${comment.createdAt}`);
      out.push(`URL: ${comment.url}`);
      out.push("");
      out.push(comment.bodyText.trim() || "(empty comment)");
      out.push("");
    }

    out.push("---");
    out.push("");
  }

  return out.join("\n").trimEnd() + "\n";
}

async function main(): Promise<void> {
  await checkDependency("gh");
  await checkDependency("fzf");

  const prUrlArg = process.argv[2];
  if (!prUrlArg) {
    usage();
    process.exit(1);
  }

  const { owner, repo, number, normalizedUrl } = parsePrUrl(prUrlArg);
  const allThreads = await fetchAllReviewThreads(owner, repo, number);
  const selectable = gatherSelectableThreads(allThreads);

  if (selectable.length === 0) {
    fail("no unresolved file-anchored review threads found");
  }

  const selected = await selectThreadsInteractive(selectable);
  if (selected.length === 0) {
    fail("no threads selected");
  }

  const markdown = formatMarkdown(selected, number, `${owner}/${repo}`, normalizedUrl);
  process.stdout.write(markdown);
}

await main();
