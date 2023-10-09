import logging
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from src.api.v1.routers import app as api_app
from src.api.v1.routers import settings as api_settings
from src.api.v1.routers import proxy as api_proxy
from src.core.exception import CustomException
from src.core.logger import logger
from src.schemas.errorResponse import ErrorResponse
from fastapi.responses import HTMLResponse

uvicorn_logger = logging.getLogger("uvicorn")

for handler in uvicorn_logger.handlers:
    uvicorn_logger.removeHandler(handler)
for handler in logger._error_logger.handlers: 
    uvicorn_logger.addHandler(handler)

uvicorn_logger.setLevel(logging.INFO)

app = FastAPI(
        title="AppManae API",
        # summary="[ Base URL: /api/v1 ]",
        description="This documentation describes the AppManage API.",
        version="0.0.1",
        docs_url=None
    )

app.mount("/static", StaticFiles(directory="swagger-ui"), name="static")

@app.get("/docs", response_class=HTMLResponse,include_in_schema=False)
async def custom_swagger_ui_html():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Websoft9 API</title>
        <link rel="stylesheet" type="text/css" href="/static/swagger-ui.css">
        <script src="/static/swagger-ui-bundle.js"></script>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script>
        const ui = SwaggerUIBundle({
            url: "/openapi.json",
            dom_id: '#swagger-ui',
            presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
            layout: "BaseLayout"
        })
        </script>
    </body>
    </html>
    """

# remove 422 responses
@app.on_event("startup")
async def remove_422_responses():
    openapi_schema = app.openapi()
    for path, path_item in openapi_schema["paths"].items():
        for method, operation in path_item.items():
            operation["responses"].pop("422", None)
    app.openapi_schema = openapi_schema

#custom error handler
@app.exception_handler(CustomException)
async def custom_exception_handler(request, exc: CustomException):
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(message=exc.message, details=exc.details).model_dump(),
    )

# 422 error handler:set 422 response to 400
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    #errors = {err['loc'][1]: err['msg'] for err in exc.errors()}
    errors = ", ".join(f"{err['loc'][1]}: {err['msg']}" for err in exc.errors())
    return JSONResponse(
        status_code=400,
        content=ErrorResponse(message="Request Validation Error", details=errors).model_dump(),
    )

app.include_router(api_app.router,tags=["apps"])
app.include_router(api_settings.router,tags=["settings"])
app.include_router(api_proxy.router,tags=["proxys"])