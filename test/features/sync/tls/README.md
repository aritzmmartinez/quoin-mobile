# Test certificate

`cert.pem` and `key.pem` are a self-signed certificate and its key made for
`pinned_client_test.dart` only. They protect nothing and are not used by the
app: the test serves HTTPS with them to check that the client trusts a
certificate by its pin and refuses any other.
