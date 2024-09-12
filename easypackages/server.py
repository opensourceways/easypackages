import uvicorn


def main() -> None:
    """Entrypoint of the application."""
    server_port = 12345
    uvicorn.run(
        "app:get_app",
        workers=1,
        host="0.0.0.0",
        port=server_port,
        reload=False,
        factory=True,
    )


if __name__ == "__main__":
    main()
