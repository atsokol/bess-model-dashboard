// See https://observablehq.com/framework/config for documentation.
export default {
  // The app’s title; used in the sidebar and webpage titles.
  title: "Ukraine BESS revenue model",
  // Set base path for GitHub Pages deployment
  base: "/bess-model-dashboard",
  // The pages and sections in the sidebar. If you don’t specify this option,
  // all pages will be listed in alphabetical order. Listing pages explicitly
  // lets you organize them into sections and have unlisted pages.
  pages: [
    {name: "Overview", path: "/"},
    {name: "Model description", path: "/model-description"},
    {name: "Revenues", path: "/revenue-analysis"},
    {name: "Energy flow", path: "/energy-flow-analysis"},
    {name: "Scenario analysis", path: "/scenario-comparison"}
  ],

  // Content to add to the head of the page, e.g. for a favicon:
  head: '<link rel="icon" href="observable.png" type="image/png" sizes="32x32">\n<link rel="stylesheet" href="/styles.css">',

  // Header with controls placeholder
  header: `<div style="background: var(--theme-background-alt); border-bottom: 1px solid var(--theme-foreground-faintest); padding: 0.5rem 1rem;">
    <div style="max-width: 1152px; margin: 0 auto;">
      <small style="color: var(--theme-foreground-muted);">💡 Use the controls at the top of each page to adjust aFRR quality and charging parameters</small>
    </div>
  </div>`,

  // The path to the source root.
  root: "src",

  // Some additional configuration options and their defaults:
  // theme: "default", // try "light", "dark", "slate", etc.
  // header: "", // what to show in the header (HTML)
  // footer: "Built with Observable.", // what to show in the footer (HTML)
  // sidebar: true, // whether to show the sidebar
  // toc: true, // whether to show the table of contents
  // pager: true, // whether to show previous & next links in the footer
  // output: "dist", // path to the output root for build
  // search: true, // activate search
  // linkify: true, // convert URLs in Markdown to links
  // typographer: false, // smart quotes and other typographic improvements
  // preserveExtension: false, // drop .html from URLs
  // preserveIndex: false, // drop /index from URLs
};
