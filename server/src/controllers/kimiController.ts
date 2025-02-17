import { Request, Response } from "express";
import { OpenAI } from "openai";
import { ChatCompletionMessageParam } from "openai/resources";
import dotenv from "dotenv";

dotenv.config();

const client: OpenAI = new OpenAI({
  apiKey: process.env.KIMI_API_KEY,
  baseURL: "https://api.moonshot.cn/v1",
});

async function generateResponse(
  messages: ChatCompletionMessageParam[]
): Promise<string> {
  try {
    const completion = await client.chat.completions.create({
      model: "moonshot-v1-8k",
      messages: [
        {
          role: "system",
          content:
            "你是游戏《饥荒》中的道具切斯特，现在有了说话的能力，后续聊天要求: 1.回复控制在20个字以内 2.你是玩家冒险中的伙伴，表现得自然一点",
        },
        ...messages,
      ],
      temperature: 0.3,
    });
    return completion.choices[0].message.content || "";
  } catch (error) {
    console.error("Error generating response from OpenAI:", error);
    throw new Error("Failed to generate response");
  }
}

export class KimiController {
  public async callKimiApi(req: Request, res: Response): Promise<void> {
    const { messages } = req.body;
    console.log("REQ====>", messages);

    if (!messages) {
      res.status(400).json({ error: "Missing messages in request body" });
      return;
    }
    try {
      const response = await generateResponse(messages);
      res.status(200).json({ response });
      console.log("response====>", response);
    } catch (error) {
      console.log("error====>", error);

      res
        .status(500)
        .json({ error: "An error occurred while calling Kimi API" });
    }
  }
}
