from fastapi import FastAPI
from starlette_exporter import PrometheusMiddleware, handle_metrics
from os import environ
from configparser import SafeConfigParser

parser = SafeConfigParser(environ)
parser.read('config.ini')


app: FastAPI = FastAPI()
app.add_middleware(PrometheusMiddleware, app_name="eks_python_demo", group_paths=True, prefix="python_demo")
app.add_route("/metrics", handle_metrics)

@app.get("/")
async def root():
    return {"message": parser.get('DEFAULT', 'DEMO_ROOT_RESPONSE', vars=environ)}

@app.get("/api")
async def api():
    return {"message": parser.get('DEFAULT', 'DEMO_API_RESPONSE', vars=environ)}
