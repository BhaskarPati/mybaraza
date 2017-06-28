SELECT message_data,
position('.' in message_data),
length(message_data),
length(message_data) - position('.' in message_data),
trim(substring(message_data from 1 for position('.' in message_data)-1)),
trim(substring(message_data from position('.' in message_data) + 1 for length(message_data)))
FROM messages


UPDATE messages SET message_code = trim(substring(message_data from 1 for position('.' in message_data)-1));
UPDATE messages SET message_data = trim(substring(message_data from position('.' in message_data) + 1 for length(message_data)));
