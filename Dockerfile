FROM barichello/godot-ci:4.7.2 AS builder

WORKDIR /game
COPY . .

RUN godot --headless --path /game --import

RUN mkdir -p /output && \
    godot --headless --path /game --export-release "Web" /output/index.html

FROM nginx:alpine

COPY --from=builder /output/ /usr/share/nginx/html/
COPY thumbnail.png /usr/share/nginx/html/thumbnail.png

EXPOSE 80
