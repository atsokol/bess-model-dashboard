import { getHighlighter } from "shiki";

export default {
  // ...existing config...
  shiki: async () => {
    return await getHighlighter({
      themes: ["nord", "github-light", "github-dark"],
      langs: ["js", "javascript", "python", "r", "json", "csv"]
    });
  }
};
