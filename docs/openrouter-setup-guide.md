# OpenRouter Configuration with AI SDK

This guide shows how to properly connect to OpenRouter using the `@ai-sdk/openai` package. You can use this exact setup to connect to any model (like OpenClaw or free variants).

## 1. Required Packages
Ensure you have the OpenAI provider installed from the Vercel AI SDK:
```bash
npm install @ai-sdk/openai ai
```

## 2. Environment Variables
Add your OpenRouter key to your `.env.local`:
```env
OPEN_ROUTER_API_KEY=sk-or-v1-your-key-here
```

## 3. Creating the Provider Instance
Initialize a custom OpenAI provider instance, but override the `baseURL` to point to OpenRouter instead of OpenAI:

```typescript
import { createOpenAI } from "@ai-sdk/openai"

// Create the custom provider
const openrouter = createOpenAI({
    baseURL: 'https://openrouter.ai/api/v1',
    apiKey: process.env.OPEN_ROUTER_API_KEY,
})
```

## 4. Using the Free Tier with Online Research capabilities
Once your provider is initialized, you can call standard Vercel AI SDK functions like `streamText` or `generateText`. 

To use free models and enable **web research**, append `:free:online` to the model name!

### Example Route Handler (`app/api/chat/route.ts`)

```typescript
import { createOpenAI } from "@ai-sdk/openai";
import { streamText, convertToModelMessages } from "ai";

const openrouter = createOpenAI({
    baseURL: 'https://openrouter.ai/api/v1',
    apiKey: process.env.OPEN_ROUTER_API_KEY,
});

export async function POST(req: Request) {
    const { messages } = await req.json();

    // 1. Standard Free Router (Lets OpenRouter pick the best free model)
    // const model = openrouter('openrouter/free');
    
    // 2. Specific Free Model with REAL-TIME ONLINE RESEARCH enabled
    const model = openrouter('openai/gpt-oss-20b:free:online');

    const result = await streamText({
        model,
        system: "You are a helpful assistant. Provide answers using the live web when necessary.",
        messages: await convertToModelMessages(messages),
    });

    return result.toTextStreamResponse();
}
```

## Important Notes on OpenRouter
- The `::online` feature only works on models that support it, but many of the major free variants (like `openai/gpt-oss-20b:free`) support it.
- **Routing**: If you use `'openrouter/free'`, it will randomly assign a capable free tier model.
- **OpenClaw Integration**: If you need to route to a specific OpenClaw model that you're hosting or using via OpenRouter, just swap the string in `openrouter('your-model-name-here')`.
