
import 'package:linksys_moab/util/validator.dart';
import 'package:linksys_moab/utils.dart';
import 'package:test/test.dart';

void main() {
  group('test json mask', () {
    test('password case', () async {
      const str = '''
        [I] TIME: 2022-08-09T23:27:33.687797
        REQUEST---------------------------------------------------
        URL: https://qa-us1-api.linksys.cloud/v1/auth/login/password, METHOD: POST
        HEADERS: {X-Linksys-Moab-Site-Id: b6b70875-9ec4-45eb-9792-2545ccc2bc5d, content-type: application/json; charset=utf-8, accept: application/json, X-Linksys-Moab-App-Id: ec4496fe-ec90-466a-8354-73ea6b272565, X-Linksys-Moab-App-Secret: gmq2wvqzTK/voG5TauzLqemPt4TTtAvPGFS22c85bn/6GyzlrzYpV5xOoQ2Na/VBO9zrjnMJhe3Cegd9X3zSsyeS/BZhH3lx39Ti/AUujj13nkew3gIDz2alUx3x2N+WOVLC8YW07YJtP4LddXlMR9/SgZP30jieovFkhL6houE=}
        BODY: {"token":"4EE7E2CE-356D-4538-B769-FEB4D41FB05C","password":"Linksys123!"}
        ---------------------------------------------------REQUEST END
      ''';
      final actual = Utils.maskJsonValue(str, ['password']);
      expect(actual.indexOf('Linksys123!'), -1);
    });

    test('cert case', () async {
      const str = '''
      [I] TIME: 2022-08-09T23:33:16.364817
      RESPONSE---------------------------------------------------
      URL: https://qa-us1-api.linksys.cloud/v1/primary-tasks/3881415c-0a58-4f70-ab16-4da9f8d92df3?token=%7Btoken%7D, METHOD: GET
      HEADERS: {X-Linksys-Moab-Site-Id: b6b70875-9ec4-45eb-9792-2545ccc2bc5d, content-type: application/json, accept: application/json, X-Linksys-Moab-App-Id: ec4496fe-ec90-466a-8354-73ea6b272565, X-Linksys-Moab-App-Secret: gmq2wvqzTK/voG5TauzLqemPt4TTtAvPGFS22c85bn/6GyzlrzYpV5xOoQ2Na/VBO9zrjnMJhe3Cegd9X3zSsyeS/BZhH3lx39Ti/AUujj13nkew3gIDz2alUx3x2N+WOVLC8YW07YJtP4LddXlMR9/SgZP30jieovFkhL6houE=, X-Linksys-Moab-Task-Secret: fd61efa4-208f-4149-9aef-b4df46ade35f}
      RESPONSE: 200, {"taskType":"CREATE_ACCOUNT_CERTIFICATE","data":{"id":"RET-A1:e5c883d2-0868-4a2e-9b7f-0eb26dd2d7db","rootCaId":"RET-ROOT1","expiration":"2024-08-08T15:33:11.000+00:00","serialNumber":"50C9B11892F1ED4709EDD86028874B45AF5950BF","publicKey":"-----BEGIN CERTIFICATE-----\nMIIDQTCCAiugAwIBAgIUUMmxGJLx7UcJ7dhgKIdLRa9ZUL8wCwYJKoZIhvcNAQEL\nMC8xDzANBgNVBAgMBmdsb2JhbDEPMA0GA1UEAwwGUkVULUExMQswCQYDVQQHDAJx\nYTAeFw0yMjA4MDkxNTMzMTFaFw0yNDA4MDgxNTMzMTFaMIGJMQ8wDQYDVQQIDAZn\nbG9iYWwxCzAJBgNVBAYTAkFDMS0wKwYDVQQLDCRlNWM4ODNkMi0wODY4LTRhMmUt\nOWI3Zi0wZWIyNmRkMmQ3ZGIxLTArBgNVBAMMJDM1MTZmYzJjLTY2YzktNGNhOS1i\nYTMwLTQzNGM0ZWU4MjNiYzELMAkGA1UEBwwCcWEwggEiMA0GCSqGSIb3DQEBAQUA\nA4IBDwAwggEKAoIBAQCh+/Hvwi8LiFIeg/m4LKjIos/9SigLsW746wSdRJ2CD+ZT\nmP1yS8/w1QFrxHbohoRynOza2YekIQXpXQm5kJkcKT7B1wxY2aIePZe
      q3nQ5U25t\nMjSTddKdPDEwSdr7iGKnGUmt2sm/eHI4YNe6V0K7FQNMCr7cYvLNsjYQbntNDEhQ\nwui5MTb6xd4B8fkL9NgS13uC92/LIPUCzNGUy7XPfqdYAmVylOjyvUI7GZKpjEjf\n4VBMbIijZHHpiUbuA0+KVqjUw+pwiTxMhgnK9C1hd7uiJAUbonkm8rLHLmakiGET\nEMxrFC8nzZOHnDQeKorYUHzDrxt9JBGqxeTRlf+1AgMBAAEwCwYJKoZIhvcNAQEL\nA4IBAQCW/218Q84sHQ+Ec8wLAuPIJYw1mPjZ6qggcVCHlFmeu17Hs/qMlcoucqSp\nigav5e198pfZ+b0kld+rhjQmKT7Sq5xpz4jwcUEVvBRgB+ZGXRPvhTVBVLnXFRj7\nRPc54LnDLxbF8uNG0EE04ZK7n7G2xE0PgNTwcchHrMWOUJZmZYJlZXSlPChowRGM\nRbIGXwSOY47wUgLGg93D5Fh4a9ec3OKR5u/wM158/LuzK2+JyRmBtHtdldou+0sL\ners0CF+sROppxxPZmC7ATDz32eK0if7+1s0l0/1XqlbWg7QlMDXur7zPVponMdo2\nH66JEn7K17DMhr7NVvw6qK+uZc31\n-----END CERTIFICATE-----\n","privateKey":"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCh+/Hvwi8LiFIe\ng/m4LKjIos/9SigLsW746wSdRJ2
      CD+ZTmP1yS8/w1QFrxHbohoRynOza2YekIQXp\nXQm5kJkcKT7B1wxY2aIePZeq3nQ5U25tMjSTddKdPDEwSdr7iGKnGUmt2sm/eHI4\nYNe6V0K7FQNMCr7cYvLNsjYQbntNDEhQwui5MTb6xd4B8fkL9NgS13uC92/LIPUC\nzNGUy7XPfqdYAmVylOjyvUI7GZKpjEjf4VBMbIijZHHpiUbuA0+KVqjUw+pwiTxM\nhgnK9C1hd7uiJAUbonkm8rLHLmakiGETEMxrFC8nzZOHnDQeKorYUHzDrxt9JBGq\nxeTRlf+1AgMBAAECggEAGvAV7jAeGD4hn/MFLJh6sjEHQ0FZkwY9JPaahBfk1LwV\nqunani8W499cduJLfwRd0tyfdA6wZL5cKBChnSM7nygJyH0dj8oTkJFgH1mSvPTP\nvKeYgDxcG+tmZ7gki2eFNnI5Y0jq+6VJY3BRd+rqjUejjnoL/wUSiVwdaxKgfTGt\nXePC5NWmw6XxS6l8sJ107tGktH/nG5NONVcb3jXVA1rqXrEHWSrmSLBBUUsAkZNE\nVRhs8eqakqxg/asErbogxKNlQlUcsHsNGQPo0cDT73P8naoEbJJqQ4vo3Mj1sZKb\nITMPlB6gGfL0XJNaM6H64dG5YLggkR8mmLzZaJgYYQKBgQC3l1mDLdbcF7VrRKGV\nx0cWjGcU0fzWj7S8CQDOsW98G6OoTRnMvzJaqnoA5geewUoys7yzEt4FP2SSUy90\nepf7JQ7xjjRX8PnvFpW/dqzJz99jTXTdeqc
      2pBqtiK14320XN2vG8uKkkeTl4gtH\nDI+KReoIP1QwEZBtPN66MkfeoQKBgQDh3v8yUA9Yv5FPT1OJ7DvMW9uTH4brPoZ7\nfjVUrMpvo/eEri05bk3YdtEd0N9uavdXU/3nSISbZsu6331DvPM1FyJt/Zz0Xl1A\nLzz90Oneg9OYIQpoQCt1A2IIJvdNQG8fIt1M2R8mc1T1+u5+WqJZGbqtC2GT74tP\ncu/QF2XslQKBgDu9Ds5lgw141XqDCYUgI9yNcRlQPtJeTnQFBfM7v0gGAlnIRMXf\nzPW9lRdnwkEBKjCXVaZ7VC0m9IW8dauUHJIG+/bTy+p1qg4HLlDvv8enUUwRrx5G\nQ9S+z0N6PuAe63NrgDFrZR4hrvayd/L1fluC5mUqni1J+dHhxaOWqtYhAoGBAKoX\nC4YP0/65A+v9iKMsSjuyUL+R1kAAbbVBbVe+ZxN7HkHECDpfXi/MCd2yFQ9JbclN\nbr5kVbfQyUqIUgRYna01JrA9c5xyEzbqW7unPvZZv1WoS/YFnLQZQBFzhneeNg/0\naUIdnt+NqkUyGbb8+ZSvU2xMTcbhdL73hq/lbtOhAoGAXfEaWQkxAeNm6+QrQj4h\ndgMZBaekegPwnlbpQLjo20nL+xvo+ncGRcQQROegEx2FSNMZeXxwFIcMLwB+dAKq\ntu7Rc5Fui6+f+NlDgSDnQitWqThUhj6v874oDoV8He15G+ISUqTv1BG/F+ckFb7n\nLcLkBBUvrINM2nR3/pit8WM=\n-----END PRIVATE KEY-----\n"}}
      ---------------------------------------------------RESPONSE END
      ''';
      final actual = Utils.maskJsonValue(str, ['publicKey', 'privateKey']);
      expect(actual.indexOf('-----BEGIN CERTIFICATE-----'), -1);
      expect(actual.indexOf('-----BEGIN PRIVATE KEY-----'), -1);

    });
  });
}
