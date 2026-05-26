import type { FC } from "hono/jsx";

type Props = {
  title: string;
  children: unknown;
};

export const Layout: FC<Props> = ({ title, children }) => (
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>{title}</title>
      <script src="https://unpkg.com/htmx.org@1.9.12" crossorigin="anonymous" />
      <style>{`
        body { font-family: system-ui, sans-serif; max-width: 640px; margin: 2rem auto; padding: 0 1rem; }
        h1 { font-size: 1.5rem; margin-bottom: 1.5rem; }
        ul { list-style: none; padding: 0; }
        li { display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem 0; border-bottom: 1px solid #eee; }
        li.done span { text-decoration: line-through; color: #888; }
        button { cursor: pointer; padding: 0.25rem 0.75rem; border: 1px solid #ccc; border-radius: 4px; background: #f5f5f5; }
        button:hover { background: #e0e0e0; }
        form.add-task { display: flex; gap: 0.5rem; margin-top: 1.5rem; }
        form.add-task input { flex: 1; padding: 0.4rem 0.75rem; border: 1px solid #ccc; border-radius: 4px; }
        form.add-task button { background: #0070f3; color: white; border-color: #0070f3; }
        form.add-task button:hover { background: #005bb5; }
        form.add-task { flex-wrap: wrap; }
        ul.errors { flex-basis: 100%; margin: 0.25rem 0 0; padding: 0; list-style: none; }
        ul.errors li { display: block; padding: 0; border: none; color: #c0392b; font-size: 0.85rem; }
        p.error { color: #c0392b; margin: 0.5rem 0; font-size: 0.9rem; }
      `}</style>
    </head>
    <body>
      <h1>{title}</h1>
      {children}
    </body>
  </html>
);
