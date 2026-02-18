# remotion-video

Generate videos using **Remotion** — a React-based video composition framework. Write videos in TypeScript/React.

## When to use

- Creating animated explainer videos, intros, or demos
- Building dynamic video content from React components
- Rendering videos programmatically as part of a workflow
- Previewing video compositions during development

## What happens

- `install` — Installs Remotion and FFmpeg (system dependency)
- `render` — Renders a video composition to MP4/WebM file
- `preview` — Starts a preview server to live-edit and test compositions

## Setup

### Installation

First, install Remotion and its dependencies:

```bash
bash skills/remotion-video/run.sh install
```

This will:
1. Install `remotion`, `@remotion/cli`, and `@remotion/player` in `apps/web`
2. Detect your OS and install FFmpeg (required for rendering)

### Create a video composition

Create a React component in `apps/web/src/videos/`:

```tsx
// apps/web/src/videos/MyIntroVideo.tsx
import { AbsoluteFill, useVideoConfig } from 'remotion';

export const MyIntroVideo = () => {
  const { durationInFrames, fps } = useVideoConfig();

  return (
    <AbsoluteFill style={{ backgroundColor: '#1f2937', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <h1 style={{ color: 'white', fontSize: 48, margin: 0 }}>
        Welcome to Remotion
      </h1>
    </AbsoluteFill>
  );
};
```

Register it in your Root composition:

```tsx
// apps/web/src/videos/Root.tsx
import { Composition } from 'remotion';
import { MyIntroVideo } from './MyIntroVideo';

export const Root = () => {
  return (
    <Composition
      id="MyIntroVideo"
      component={MyIntroVideo}
      durationInFrames={150}
      fps={30}
      width={1280}
      height={720}
    />
  );
};
```

## Usage

### Preview a composition

Start the preview server to live-edit your video:

```bash
bash skills/remotion-video/run.sh preview MyIntroVideo
```

Opens at `http://localhost:3000` — you can edit the component and see changes in real-time.

### Render to file

Render a composition to MP4:

```bash
bash skills/remotion-video/run.sh render MyIntroVideo output.mp4
```

### Render with custom props

Pass dynamic data to your composition:

```bash
bash skills/remotion-video/run.sh render MyIntroVideo output.mp4 '{"title":"Hello World","duration":5}'
```

Access props in your component:

```tsx
export const MyIntroVideo: React.FC<{ title: string; duration: number }> = ({
  title,
  duration,
}) => {
  // ... use title and duration
};
```

## Advanced

### Output formats

By default, renders as MP4. You can specify output format by file extension:

```bash
bash skills/remotion-video/run.sh render MyVideo output.webm
bash skills/remotion-video/run.sh render MyVideo output.gif
```

### Full render with custom settings

For more control, use `pnpm remotion` directly in `apps/web`:

```bash
cd apps/web
pnpm remotion render MyIntroVideo output.mp4 --width 1920 --height 1080 --fps 60
```

See [Remotion CLI docs](https://www.remotion.dev/docs) for all options.

## How it works

Remotion renders React components as videos:

1. Each composition is a React component with Remotion hooks
2. Timeline is controlled by frame numbers (not time)
3. Remotion uses FFmpeg under the hood to encode video
4. Output is MP4/WebM with full codec support

## Troubleshooting

**"FFmpeg not found"**
- Install FFmpeg: `brew install ffmpeg` (macOS) or `apt-get install ffmpeg` (Linux)

**"Composition not found"**
- Ensure composition is registered in your Root.tsx file
- Check the composition ID matches exactly

**"Out of memory during render"**
- Reduce resolution: `--width 1280 --height 720`
- Render shorter clips and concatenate later

## Resources

- [Remotion Docs](https://www.remotion.dev/)
- [Remotion API Reference](https://www.remotion.dev/docs/api)
- [Video Composition Templates](https://www.remotion.dev/docs/tutorials)
