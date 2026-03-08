import { NextResponse } from "next/server";
import { Groq } from "groq-sdk";
import { ethers } from "ethers";

export async function POST(req: Request) {
  try {
    const { txContext, userOpHash } = await req.json();
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || "YOUR_GROQ_API_KEY_HERE" });
    const aiPrivateKey = process.env.AI_PRIVATE_KEY || "0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abcd";
    const wallet = new ethers.Wallet(aiPrivateKey);

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
