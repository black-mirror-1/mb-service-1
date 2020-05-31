
FROM node:alpine

ADD main.js /app/main.js

ENTRYPOINT [ "node", "/app/main.js" ]