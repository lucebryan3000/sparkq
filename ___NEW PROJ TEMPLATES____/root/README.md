# Project

## Quick Start

```bash
# Install dependencies
pnpm install

# Start database
docker compose up -d db

# Run migrations and seed
pnpm db:migrate
pnpm db:seed

# Start development server
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000).

## Commands

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start development server |
| `pnpm build` | Build for production |
| `pnpm start` | Start production server |
| `pnpm lint` | Run ESLint |
| `pnpm format` | Format with Prettier |
| `pnpm typecheck` | Run TypeScript checks |
| `pnpm test` | Run unit tests |
| `pnpm test:e2e` | Run E2E tests |
| `pnpm db:studio` | Open Prisma Studio |

## Docker

```bash
# Full stack
docker compose up -d

# Rebuild from scratch
docker compose down -v && docker compose up -d

# View logs
docker compose logs -f
```

## Structure

```
src/
├── app/           # Next.js App Router
├── components/    # React components
├── hooks/         # Custom hooks
├── lib/           # Utilities
├── services/      # Business logic
└── types/         # TypeScript types
prisma/
├── schema.prisma  # Database schema
└── seed.ts        # Seed data
testing/
├── setup.ts       # Jest setup
├── fixtures/      # Test fixtures
└── custom/        # Integration tests
```

## Environment

Copy `.env.example` to `.env.local` and configure:

```bash
cp .env.example .env.local
```

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript (strict mode)
- **Database**: PostgreSQL + Prisma
- **Styling**: Tailwind CSS + shadcn/ui
- **State**: Zustand + SWR
- **Testing**: Jest + Playwright
