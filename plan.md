# stackcoin 2020

## overall plans

- sqlite -> postgres
- types in all the places
- maybe use the multi-threading mode of crystal?

## files

stackcoin.cr

### core

stackcoin/core.cr

stackcoin/core/bank.cr
stackcoin/core/info.cr

### bot

stackcoin/bot.cr

stackcoin/bot/parser.cr

stackcoin/bot/commands/balance.cr
stackcoin/bot/commands/circulation.cr
stackcoin/bot/commands/dole.cr
stackcoin/bot/commands/graph.cr
stackcoin/bot/commands/leaderboard.cr
stackcoin/bot/commands/transactions.cr
stackcoin/bot/commands/send.cr
stackcoin/bot/commands/ban.cr
stackcoin/bot/commands/unban.cr
stackcoin/bot/commands/help.cr
stackcoin/bot/commands/auth.cr

### api

stackcoin/api.cr

stackcoin/api/controllers/root.cr
stackcoin/api/controllers/auth.cr
stackcoin/api/controllers/user.cr
stackcoin/api/controllers/transaction.cr

stackcoin/api/views/

### models

stackcoin/models.cr
stackcoin/models/user.cr
stackcoin/models/bot_user.cr
stackcoin/models/discord_user.cr
stackcoin/models/transaction.cr
stackcoin/models/request.cr
