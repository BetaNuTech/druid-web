Delayed::Worker.queue_attributes = {
  high_priority: { priority: -10 },
  low_priority: { priority: 10 },
  lead_dedupe: { priority: 50 },
  mailers: { priority: 10 },
  messages: { priority: 10 }
}
