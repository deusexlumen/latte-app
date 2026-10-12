# PURPOSE: ApiClient.resolve_proxy_config: Defaults bei leerem Dictionary, url-/token-Override, Fallback bei ungueltigen Werten.
# ARCHITECTURE: test
# DEPENDENCIES: ApiClient
# PIPELINE: test
# LAST_VALIDATED: 2026-09-18
extends GutTest

const DEFAULT_URL := "http://localhost:8787"


func test_empty_dict_returns_defaults() -> void:
	var config := ApiClient.resolve_proxy_config({})
	assert_eq(str(config["url"]), DEFAULT_URL)
	assert_eq(str(config["token"]), "")


func test_url_override_is_used() -> void:
	var config := ApiClient.resolve_proxy_config({"url": "http://gm.example:9999"})
	assert_eq(str(config["url"]), "http://gm.example:9999")
	assert_eq(str(config["token"]), "")


func test_token_override_is_used() -> void:
	var config := ApiClient.resolve_proxy_config({"token": "geheim"})
	assert_eq(str(config["token"]), "geheim")
	assert_eq(str(config["url"]), DEFAULT_URL)


func test_url_and_token_override_together() -> void:
	var config := ApiClient.resolve_proxy_config({"url": "https://gm.example", "token": "abc123"})
	assert_eq(str(config["url"]), "https://gm.example")
	assert_eq(str(config["token"]), "abc123")


func test_empty_url_string_falls_back_to_default() -> void:
	var config := ApiClient.resolve_proxy_config({"url": ""})
	assert_eq(str(config["url"]), DEFAULT_URL)


func test_whitespace_only_url_falls_back_to_default() -> void:
	var config := ApiClient.resolve_proxy_config({"url": "   "})
	assert_eq(str(config["url"]), DEFAULT_URL)


func test_non_string_url_falls_back_to_default() -> void:
	var config := ApiClient.resolve_proxy_config({"url": 42})
	assert_eq(str(config["url"]), DEFAULT_URL)


func test_non_string_token_falls_back_to_empty() -> void:
	var config := ApiClient.resolve_proxy_config({"token": true})
	assert_eq(str(config["token"]), "")
	assert_eq(str(config["url"]), DEFAULT_URL)
