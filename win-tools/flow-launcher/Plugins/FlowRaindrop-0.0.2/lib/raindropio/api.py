from __future__ import annotations

import datetime
import enum
import json
from typing import Any, Dict, Optional, Union

import requests
from requests_oauthlib import OAuth2Session


def create_oauth2session(*args: Any, **kwargs: Any) -> OAuth2Session:
    session = OAuth2Session(*args, **kwargs)

#    session.register_compliance_hook("access_token_response", update_expires)
#    session.register_compliance_hook("refresh_token_response", update_expires)
    return session


class API:
    """Provides communication to the Raindrop.io API server.

    :param token: An access token for authorization.
    :type token: string or dict.
    """

    URL_AUTHORIZE = "https://raindrop.io/oauth/authorize"
    URL_ACCESS_TOKEN = "https://raindrop.io/oauth/access_token"
    URL_REFRESH = "https://raindrop.io/oauth/access_token"

    ratelimit: Optional[int] = None
    ratelimit_remaining: Optional[int] = None
    ratelimit_reset: Optional[int] = None

    def __init__(
        self,
        token: Union[str, Dict[str, Any]],
        client_id: Optional[str] = None,
        client_secret: Optional[str] = None,
        token_type: str = "Bearer",
    ) -> None:
        self.token = token
        self.client_id = client_id
        self.client_secret = client_secret
        self.token_type = token_type

        self.session = None

        self.open()

    def __enter__(self) -> API:
        if not self.session:
            self.open()

        return self

    def __exit__(self, type, value, traceback) -> None:  # type: ignore
        self.close()

    def open(self) -> None:
        self.close()
        self.session = self._create_session()

    def close(self) -> None:
        if self.session:
            self.session.close()
            self.session = None

    def _create_session(self) -> OAuth2Session:
        extra: Optional[Dict[str, Any]]
        if self.client_id and self.client_secret:
            extra = {
                "client_id": self.client_id,
                "client_secret": self.client_secret,
            }
        else:
            extra = None

        def update_token(newtoken: str) -> None:
            self.token = newtoken

        if isinstance(self.token, str):
            token = {"access_token": self.token}
        else:
            token = self.token

        return OAuth2Session(
            self.client_id,
            token=token,
            auto_refresh_kwargs=extra,
            auto_refresh_url=self.URL_REFRESH,
            token_updater=update_token,
        )

    def _json_unknown(self, obj: Any) -> Any:
        if isinstance(obj, enum.Enum):
            return obj.value

        if isinstance(obj, datetime.datetime):
            return obj.isoformat()

        raise TypeError(
            f"Object of type {obj.__class__.__name__} " f"is not JSON serializable"
        )

    def _to_json(self, obj: Any) -> Optional[str]:
        if obj is not None:
            return json.dumps(obj, default=self._json_unknown)
        else:
            return None

    def _on_resp(self, resp: Any) -> None:
        def get_int(name: str) -> Optional[int]:
            value = resp.headers.get(name, None)
            if value is not None:
                return int(value)
            return None

        v = get_int("X-RateLimit-Limit")
        if v is not None:
            self.ratelimit = v

        v = get_int("X-RateLimit-Remaining")
        if v is not None:
            self.ratelimit_remaining = v

        v = get_int("X-RateLimit-Reset")
        if v is not None:
            self.ratelimit_reset = v

        resp.raise_for_status()

    def _request_headers(self) -> Dict[str, str]:
        return {
            "Content-Type": "application/json",
        }

    def get(
        self, url: str, params: Optional[Dict[Any, Any]] = None
    ) -> requests.models.Response:
        """Send a GET request

        :param url: The url to send request
        :type url: str

        :param params: (optional) Dictionary, list of tuples or bytes to send
            in the query string for the :class:`Request`.

        :return: :class:`requests.Response` object
        :rtype: :class:`requests.Response`
        """

        assert self.session
        ret = self.session.get(url, headers=self._request_headers(), params=params)
        self._on_resp(ret)

        return ret

    def put(self, url: str, json: Any = None) -> requests.models.Response:
        json = self._to_json(json)

        assert self.session
        ret = self.session.put(url, headers=self._request_headers(), data=json)
        self._on_resp(ret)
        return ret

    def post(self, url: str, json: Any = None) -> requests.models.Response:
        json = self._to_json(json)

        assert self.session
        ret = self.session.post(url, headers=self._request_headers(), data=json)
        self._on_resp(ret)
        return ret

    def delete(self, url: str, json: Any = None) -> requests.models.Response:
        json = self._to_json(json)

        assert self.session
        ret = self.session.delete(url, headers=self._request_headers(), data=json)
        self._on_resp(ret)
        return ret
