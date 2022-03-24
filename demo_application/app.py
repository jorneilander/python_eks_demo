import uvicorn
from fastapi import FastAPI
from pydantic import BaseSettings

from starlette_exporter import PrometheusMiddleware, handle_metrics
from os import environ
from configparser import ConfigParser

parser: ConfigParser = ConfigParser(environ, strict=False)
parser.read("config.ini")

app_port: str = parser.get("DEFAULT", "APP_PORT", vars=environ, fallback="80")


class Config(BaseSettings):
    API_APP_NAME = "demo_application"
    APP_VERSION = parser.get("DEFAULT", "APP_VERSION", vars=environ, fallback="1")
    EXPOSE_PORT = int(app_port)
    DEVELOPMENT = False
    WORKERS = 1
    TIMEOUT = 5


uvicorn_config = Config()


app: FastAPI = FastAPI()
app.add_middleware(
    PrometheusMiddleware,
    app_name="eks_python_demo",
    group_paths=True,
    prefix="python_demo",
)
app.add_route("/metrics", handle_metrics)

# Since 'version' is an environment variable we _need_ to re-evaluate it to check if it has changed in order for our tests to work...
def get_version() -> int:
    """
    Get the application version from the 'APP_VERSION' environment variable.

    Returns:
        int: application version set in 'APP_VERSION' environment variable else return 1
    """

    app_version: str = parser.get("DEFAULT", "APP_VERSION", vars=environ, fallback="1")
    return int(app_version) if app_version != "" else 1


# Since the version postfix is dependant on
def get_version_postfix() -> str:
    """
    Get the conditional application version postfix

    Returns:
        str: ' version (_version_)' if version isn't 1, else return ''
    """

    # app_version: str = parser.get("DEFAULT", "APP_VERSION", vars=environ, fallback="1")
    return f" version {get_version()}" if get_version() != 1 else ""


@app.get("/")
async def root() -> str:
    root_response: str = parser.get("DEFAULT", "DEMO_ROOT_RESPONSE", vars=environ)
    return f"{root_response}{get_version_postfix()}"


@app.get("/api")
async def api() -> dict[str, str]:
    return {
        "message": parser.get("DEFAULT", "DEMO_API_RESPONSE", vars=environ),
        "version": str(get_version()),
    }


# !TODO: Create /update/{endpoint} endpoint which updates it's responses for itself as well as all instances on the cluster using the kubernetes-API.

# start config
if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=uvicorn_config.EXPOSE_PORT,
        reload=uvicorn_config.DEVELOPMENT,
        debug=uvicorn_config.DEVELOPMENT,
        workers=uvicorn_config.WORKERS,
        timeout_keep_alive=uvicorn_config.TIMEOUT,
    )
