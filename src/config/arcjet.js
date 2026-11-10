import arcjet, {
  shield,
  detectBot,
  tokenBucket,
  slidingWindow,
} from "@arcjet/node";

const aj = arcjet({
  key: process.env.ARCJET_KEY,
  rules: [
    // Shield protects your app from common attacks e.g. SQL injection
    shield({ mode: "LIVE" }),
    // Create a bot detection rule
    detectBot({
      mode: "LIVE",

      allow: ["CATEGORY:SEARCH_ENGINE", "CATEGORY:PREVIEW"],
    }),
    slidingWindow({
      mode: "LIVE",
      interval: 2,
      max: 5,
      name: "rate-limit",
    }),

    tokenBucket({
      mode: "LIVE",
      refillRate: 5,
      interval: 2,
      capacity: 10,
    }),
  ],
});

export default aj;
