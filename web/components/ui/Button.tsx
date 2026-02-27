import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { Slot } from "radix-ui"
import Link from "next/link"

import { cn } from "@/lib/utils"

// ── shadcn button primitives (keep for new code) ──────────────────────────
const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 aria-invalid:border-destructive",
  {
    variants: {
      variant: {
        default:     "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-white hover:bg-destructive/90",
        outline:     "border border-primary text-primary bg-transparent hover:bg-secondary",
        secondary:   "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost:       "text-primary hover:bg-secondary",
        link:        "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        xs:      "h-6 px-2 text-xs rounded-md",
        sm:      "h-8 px-3 rounded-md",
        lg:      "h-10 px-6 rounded-md",
        icon:    "size-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

function Button({
  className,
  variant = "default",
  size = "default",
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean
  }) {
  const Comp = asChild ? Slot.Root : "button"
  return (
    <Comp
      data-slot="button"
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}

export { Button, buttonVariants }

// ── Backward-compatible default export ────────────────────────────────────
// Maps our old API (primary/secondary/danger/ghost/outline/white + href)
// to shadcn's Button so existing components need zero changes.

type LegacyVariant = "primary" | "secondary" | "danger" | "ghost" | "outline" | "white"
type LegacySize    = "sm" | "md" | "lg"

const legacyVariantMap: Record<LegacyVariant, VariantProps<typeof buttonVariants>["variant"]> = {
  primary:   "default",
  secondary: "outline",
  danger:    "destructive",
  ghost:     "ghost",
  outline:   "outline",
  white:     "secondary",
}

const legacySizeMap: Record<LegacySize, VariantProps<typeof buttonVariants>["size"]> = {
  sm: "sm",
  md: "default",
  lg: "lg",
}

interface LegacyButtonProps {
  children:   React.ReactNode
  variant?:   LegacyVariant
  size?:      LegacySize
  href?:      string
  onClick?:   () => void
  className?: string
  type?:      "button" | "submit"
  disabled?:  boolean
}

export default function SmeButton({
  children,
  variant  = "primary",
  size     = "md",
  href,
  onClick,
  className = "",
  type      = "button",
  disabled  = false,
}: LegacyButtonProps) {
  const v = legacyVariantMap[variant]
  const s = legacySizeMap[size]

  if (href) {
    return (
      <Button asChild variant={v} size={s} className={className} disabled={disabled}>
        <Link href={href}>{children}</Link>
      </Button>
    )
  }

  return (
    <Button
      type={type}
      variant={v}
      size={s}
      onClick={onClick}
      className={className}
      disabled={disabled}
    >
      {children}
    </Button>
  )
}
