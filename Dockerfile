FROM node:alpine


WORKDIR /app


COPY package*.json ./


RUN npm install

COPY . .

EXPOSE 12345

CMD ["node", "server.js"]
