import { NextResponse } from "next/server";
import { Groq } from "groq-sdk";
import { ethers } from "ethers";

export async function POST(req: Request) {
  try {
    const { txContext, userOpHash } = await req.json();
    
    if (!process.env.GROQ_API_KEY || process.env.GROQ_API_KEY === "YOUR_GROQ_KEY") {
      return NextResponse.json({ 
        approved: false, 
        error: "GROQ_API_KEY is missing. Please set it in your environment." 
      }, { status: 500 });
    }

    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
    const aiPrivateKey = process.env.AI_PRIVATE_KEY || "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
    
    let wallet;
    try {
      wallet = new ethers.Wallet(aiPrivateKey);
    } catch (e) {
      return NextResponse.json({ 
        approved: false, 
        error: "Invalid AI_PRIVATE_KEY. Please check your configuration." 
      }, { status: 500 });
    }

    const completion = await groq.chat.completions.create({
      model: "llama-3.3-70b-versatile",
      messages: [
        { role: "system", content: "You are the LockedFI AI Guardian. Start with 'APPROVE' if safe." },
        { role: "user", content: txContext }
      ],
    });

    const decision = completion.choices[0].message.content || "";
    if (decision.includes("APPROVE")) {
      const signature = await wallet.signMessage(ethers.getBytes(userOpHash));
      return NextResponse.json({ approved: true, signature, decision });
    }
    return NextResponse.json({ approved: false, decision });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
