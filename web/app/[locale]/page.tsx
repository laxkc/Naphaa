import Hero        from "@/components/sections/Hero";
import SocialProof from "@/components/sections/SocialProof";
import Features    from "@/components/sections/Features";
import HowItWorks  from "@/components/sections/HowItWorks";
import Pricing     from "@/components/sections/Pricing";
import CallToAction from "@/components/sections/CallToAction";

export default function Home() {
  return (
    <>
      <Hero />
      <SocialProof />
      <Features />
      <HowItWorks />
      <Pricing />
      <CallToAction />
    </>
  );
}
