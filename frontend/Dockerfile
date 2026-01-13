# build
FROM node:16.13.2-alpine AS builder
ARG NODE_ENV=dev
ARG VUE_APP_API_URL
ENV VUE_APP_API_URL=$VUE_APP_API_URL
WORKDIR /usr/src/app
COPY ./package*.json ./
RUN npm install
COPY . .
RUN npm run build

# release
FROM nginx:1.22.1-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /usr/src/app/dist /usr/share/nginx/html/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]
