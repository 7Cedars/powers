const prompt = args[0]

if (
    !secrets.geminiApiKey
) {
    throw Error(
        "Need to set geminiApiKey environment variable"
    )
}

// example request: 
const geminiRequest = Functions.makeHttpRequest({
    url: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
    method: "POST",
    headers: {
        'x-goog-api-key': `${secrets.geminiApiKey}`,
        'Content-Type': 'application/json'
    },
    data: { 
      "contents": 
        [
          {
            parts: [
              { text: 'Explain how AI works in a few words' },
            ],
          },
        ],
      },
    timeout: 9000
  })

const [geminiResponse] = await Promise.all([
    geminiRequest
])
console.log("raw response", geminiResponse.data.candidates[0].content.parts[0].text)

// const result = openAiResponse.data.choices[0].text
return Functions.encodeString(geminiResponse)