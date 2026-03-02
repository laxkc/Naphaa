import Hero            from "@/components/sections/Hero";
import Demo            from "@/components/sections/Demo";
import Problem         from "@/components/sections/Problem";
import Features        from "@/components/sections/Features";
import Outcomes        from "@/components/sections/Outcomes";
import Trust           from "@/components/sections/Trust";
import HowItWorks      from "@/components/sections/HowItWorks";
import FAQ             from "@/components/sections/FAQ";
import CallToAction    from "@/components/sections/CallToAction";

export default function Home() {
  return (
    <>
      <Hero />
      <Demo />
      <Problem />
      <Features />
      <Outcomes />
      <Trust />
      <HowItWorks />
      {/* <Pricing /> */}
      <FAQ />
      <CallToAction />
    </>
  );
}
