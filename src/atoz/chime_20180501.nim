
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Chime
## version: 2018-05-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The Amazon Chime API (application programming interface) is designed for administrators to use to perform key tasks, such as creating and managing Amazon Chime accounts and users. This guide provides detailed information about the Amazon Chime API, including operations, types, inputs and outputs, and error codes.</p> <p>You can use an AWS SDK, the AWS Command Line Interface (AWS CLI), or the REST API to make API calls. We recommend using an AWS SDK or the AWS CLI. Each API operation includes links to information about using it with a language-specific AWS SDK or the AWS CLI.</p> <dl> <dt>Using an AWS SDK</dt> <dd> <p>You don't need to write code to calculate a signature for request authentication. The SDK clients authenticate your requests by using access keys that you provide. For more information about AWS SDKs, see the <a href="http://aws.amazon.com/developer/">AWS Developer Center</a>.</p> </dd> <dt>Using the AWS CLI</dt> <dd> <p>Use your access keys with the AWS CLI to make API calls. For information about setting up the AWS CLI, see <a href="https://docs.aws.amazon.com/cli/latest/userguide/installing.html">Installing the AWS Command Line Interface</a> in the <i>AWS Command Line Interface User Guide</i>. For a list of available Amazon Chime commands, see the <a href="https://docs.aws.amazon.com/cli/latest/reference/chime/index.html">Amazon Chime commands</a> in the <i>AWS CLI Command Reference</i>.</p> </dd> <dt>Using REST API</dt> <dd> <p>If you use REST to make API calls, you must authenticate your request by providing a signature. Amazon Chime supports signature version 4. For more information, see <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>When making REST API calls, use the service name <code>chime</code> and REST endpoint <code>https://service.chime.aws.amazon.com</code>.</p> </dd> </dl> <p>Administrative permissions are controlled using AWS Identity and Access Management (IAM). For more information, see <a href="https://docs.aws.amazon.com/chime/latest/ag/control-access.html">Control Access to the Amazon Chime Console</a> in the <i>Amazon Chime Administration Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/chime/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"cn-northwest-1": "chime.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "chime.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "chime.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "chime.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "chime"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociatePhoneNumberWithUser_602803 = ref object of OpenApiRestCall_602466
proc url_AssociatePhoneNumberWithUser_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId"), (kind: ConstantSegment,
        value: "#operation=associate-phone-number")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AssociatePhoneNumberWithUser_602804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_602931 = path.getOrDefault("accountId")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "accountId", valid_602931
  var valid_602932 = path.getOrDefault("userId")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "userId", valid_602932
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_602946 = query.getOrDefault("operation")
  valid_602946 = validateParameter(valid_602946, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_602946 != nil:
    section.add "operation", valid_602946
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602947 = header.getOrDefault("X-Amz-Date")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Date", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Security-Token")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Security-Token", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Content-Sha256", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Algorithm")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Algorithm", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Signature")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Signature", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-SignedHeaders", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Credential")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Credential", valid_602953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602977: Call_AssociatePhoneNumberWithUser_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_602977.validator(path, query, header, formData, body)
  let scheme = call_602977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602977.url(scheme.get, call_602977.host, call_602977.base,
                         call_602977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602977, url, valid)

proc call*(call_603048: Call_AssociatePhoneNumberWithUser_602803;
          accountId: string; body: JsonNode; userId: string;
          operation: string = "associate-phone-number"): Recallable =
  ## associatePhoneNumberWithUser
  ## Associates a phone number with the specified Amazon Chime user.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603049 = newJObject()
  var query_603051 = newJObject()
  var body_603052 = newJObject()
  add(path_603049, "accountId", newJString(accountId))
  add(query_603051, "operation", newJString(operation))
  if body != nil:
    body_603052 = body
  add(path_603049, "userId", newJString(userId))
  result = call_603048.call(path_603049, query_603051, nil, nil, body_603052)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_602803(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_602804, base: "/",
    url: url_AssociatePhoneNumberWithUser_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_603091 = ref object of OpenApiRestCall_602466
proc url_AssociatePhoneNumbersWithVoiceConnector_603093(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"), (
        kind: ConstantSegment, value: "#operation=associate-phone-numbers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AssociatePhoneNumbersWithVoiceConnector_603092(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603094 = path.getOrDefault("voiceConnectorId")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = nil)
  if valid_603094 != nil:
    section.add "voiceConnectorId", valid_603094
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603095 = query.getOrDefault("operation")
  valid_603095 = validateParameter(valid_603095, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_603095 != nil:
    section.add "operation", valid_603095
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Content-Sha256", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Algorithm")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Algorithm", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Credential")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Credential", valid_603102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603104: Call_AssociatePhoneNumbersWithVoiceConnector_603091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603104, url, valid)

proc call*(call_603105: Call_AssociatePhoneNumbersWithVoiceConnector_603091;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603106 = newJObject()
  var query_603107 = newJObject()
  var body_603108 = newJObject()
  add(path_603106, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603107, "operation", newJString(operation))
  if body != nil:
    body_603108 = body
  result = call_603105.call(path_603106, query_603107, nil, nil, body_603108)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_603091(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_603092, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_603093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_603109 = ref object of OpenApiRestCall_602466
proc url_BatchDeletePhoneNumber_603111(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeletePhoneNumber_603110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603112 = query.getOrDefault("operation")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_603112 != nil:
    section.add "operation", valid_603112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603113 = header.getOrDefault("X-Amz-Date")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Date", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Content-Sha256", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Algorithm")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Algorithm", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Signature")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Signature", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-SignedHeaders", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603121: Call_BatchDeletePhoneNumber_603109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_603121.validator(path, query, header, formData, body)
  let scheme = call_603121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603121.url(scheme.get, call_603121.host, call_603121.base,
                         call_603121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603121, url, valid)

proc call*(call_603122: Call_BatchDeletePhoneNumber_603109; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_603123 = newJObject()
  var body_603124 = newJObject()
  add(query_603123, "operation", newJString(operation))
  if body != nil:
    body_603124 = body
  result = call_603122.call(nil, query_603123, nil, nil, body_603124)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_603109(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_603110, base: "/",
    url: url_BatchDeletePhoneNumber_603111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_603125 = ref object of OpenApiRestCall_602466
proc url_BatchSuspendUser_603127(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users#operation=suspend")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_BatchSuspendUser_603126(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603128 = path.getOrDefault("accountId")
  valid_603128 = validateParameter(valid_603128, JString, required = true,
                                 default = nil)
  if valid_603128 != nil:
    section.add "accountId", valid_603128
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603129 = query.getOrDefault("operation")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = newJString("suspend"))
  if valid_603129 != nil:
    section.add "operation", valid_603129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603130 = header.getOrDefault("X-Amz-Date")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Date", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Security-Token")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Security-Token", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Content-Sha256", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Algorithm")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Algorithm", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Signature")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Signature", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-SignedHeaders", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Credential")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Credential", valid_603136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603138: Call_BatchSuspendUser_603125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_603138.validator(path, query, header, formData, body)
  let scheme = call_603138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603138.url(scheme.get, call_603138.host, call_603138.base,
                         call_603138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603138, url, valid)

proc call*(call_603139: Call_BatchSuspendUser_603125; accountId: string;
          body: JsonNode; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603140 = newJObject()
  var query_603141 = newJObject()
  var body_603142 = newJObject()
  add(path_603140, "accountId", newJString(accountId))
  add(query_603141, "operation", newJString(operation))
  if body != nil:
    body_603142 = body
  result = call_603139.call(path_603140, query_603141, nil, nil, body_603142)

var batchSuspendUser* = Call_BatchSuspendUser_603125(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_603126, base: "/",
    url: url_BatchSuspendUser_603127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_603143 = ref object of OpenApiRestCall_602466
proc url_BatchUnsuspendUser_603145(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users#operation=unsuspend")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_BatchUnsuspendUser_603144(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603146 = path.getOrDefault("accountId")
  valid_603146 = validateParameter(valid_603146, JString, required = true,
                                 default = nil)
  if valid_603146 != nil:
    section.add "accountId", valid_603146
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603147 = query.getOrDefault("operation")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_603147 != nil:
    section.add "operation", valid_603147
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603148 = header.getOrDefault("X-Amz-Date")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Date", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Security-Token")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Security-Token", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_BatchUnsuspendUser_603143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_BatchUnsuspendUser_603143; accountId: string;
          body: JsonNode; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603158 = newJObject()
  var query_603159 = newJObject()
  var body_603160 = newJObject()
  add(path_603158, "accountId", newJString(accountId))
  add(query_603159, "operation", newJString(operation))
  if body != nil:
    body_603160 = body
  result = call_603157.call(path_603158, query_603159, nil, nil, body_603160)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_603143(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_603144, base: "/",
    url: url_BatchUnsuspendUser_603145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_603161 = ref object of OpenApiRestCall_602466
proc url_BatchUpdatePhoneNumber_603163(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchUpdatePhoneNumber_603162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603164 = query.getOrDefault("operation")
  valid_603164 = validateParameter(valid_603164, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_603164 != nil:
    section.add "operation", valid_603164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Content-Sha256", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Algorithm")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Algorithm", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Signature")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Signature", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-SignedHeaders", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Credential")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Credential", valid_603171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603173: Call_BatchUpdatePhoneNumber_603161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_603173.validator(path, query, header, formData, body)
  let scheme = call_603173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603173.url(scheme.get, call_603173.host, call_603173.base,
                         call_603173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603173, url, valid)

proc call*(call_603174: Call_BatchUpdatePhoneNumber_603161; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_603175 = newJObject()
  var body_603176 = newJObject()
  add(query_603175, "operation", newJString(operation))
  if body != nil:
    body_603176 = body
  result = call_603174.call(nil, query_603175, nil, nil, body_603176)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_603161(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_603162, base: "/",
    url: url_BatchUpdatePhoneNumber_603163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_603197 = ref object of OpenApiRestCall_602466
proc url_BatchUpdateUser_603199(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_BatchUpdateUser_603198(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603200 = path.getOrDefault("accountId")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = nil)
  if valid_603200 != nil:
    section.add "accountId", valid_603200
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603201 = header.getOrDefault("X-Amz-Date")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Date", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Security-Token")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Security-Token", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Content-Sha256", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Algorithm")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Algorithm", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Signature")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Signature", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-SignedHeaders", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Credential")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Credential", valid_603207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603209: Call_BatchUpdateUser_603197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_603209.validator(path, query, header, formData, body)
  let scheme = call_603209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603209.url(scheme.get, call_603209.host, call_603209.base,
                         call_603209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603209, url, valid)

proc call*(call_603210: Call_BatchUpdateUser_603197; accountId: string;
          body: JsonNode): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603211 = newJObject()
  var body_603212 = newJObject()
  add(path_603211, "accountId", newJString(accountId))
  if body != nil:
    body_603212 = body
  result = call_603210.call(path_603211, nil, nil, nil, body_603212)

var batchUpdateUser* = Call_BatchUpdateUser_603197(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_603198,
    base: "/", url: url_BatchUpdateUser_603199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_603177 = ref object of OpenApiRestCall_602466
proc url_ListUsers_603179(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListUsers_603178(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603180 = path.getOrDefault("accountId")
  valid_603180 = validateParameter(valid_603180, JString, required = true,
                                 default = nil)
  if valid_603180 != nil:
    section.add "accountId", valid_603180
  result.add "path", section
  ## parameters in `query` object:
  ##   user-email: JString
  ##             : Optional. The user email address used to filter results. Maximum 1.
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Defaults to 100.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603181 = query.getOrDefault("user-email")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "user-email", valid_603181
  var valid_603182 = query.getOrDefault("NextToken")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "NextToken", valid_603182
  var valid_603183 = query.getOrDefault("max-results")
  valid_603183 = validateParameter(valid_603183, JInt, required = false, default = nil)
  if valid_603183 != nil:
    section.add "max-results", valid_603183
  var valid_603184 = query.getOrDefault("next-token")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "next-token", valid_603184
  var valid_603185 = query.getOrDefault("MaxResults")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "MaxResults", valid_603185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603186 = header.getOrDefault("X-Amz-Date")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Date", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Content-Sha256", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Algorithm")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Algorithm", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Signature")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Signature", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-SignedHeaders", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Credential")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Credential", valid_603192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_ListUsers_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603193, url, valid)

proc call*(call_603194: Call_ListUsers_603177; accountId: string;
          userEmail: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUsers
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userEmail: string
  ##            : Optional. The user email address used to filter results. Maximum 1.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Defaults to 100.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_603195 = newJObject()
  var query_603196 = newJObject()
  add(path_603195, "accountId", newJString(accountId))
  add(query_603196, "user-email", newJString(userEmail))
  add(query_603196, "NextToken", newJString(NextToken))
  add(query_603196, "max-results", newJInt(maxResults))
  add(query_603196, "next-token", newJString(nextToken))
  add(query_603196, "MaxResults", newJString(MaxResults))
  result = call_603194.call(path_603195, query_603196, nil, nil, nil)

var listUsers* = Call_ListUsers_603177(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_603178,
                                    base: "/", url: url_ListUsers_603179,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_603232 = ref object of OpenApiRestCall_602466
proc url_CreateAccount_603234(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAccount_603233(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603235 = header.getOrDefault("X-Amz-Date")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Date", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Security-Token")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Security-Token", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Content-Sha256", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Algorithm")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Algorithm", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Signature")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Signature", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-SignedHeaders", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Credential")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Credential", valid_603241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603243: Call_CreateAccount_603232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_603243.validator(path, query, header, formData, body)
  let scheme = call_603243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603243.url(scheme.get, call_603243.host, call_603243.base,
                         call_603243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603243, url, valid)

proc call*(call_603244: Call_CreateAccount_603232; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_603245 = newJObject()
  if body != nil:
    body_603245 = body
  result = call_603244.call(nil, nil, nil, nil, body_603245)

var createAccount* = Call_CreateAccount_603232(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_603233, base: "/", url: url_CreateAccount_603234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_603213 = ref object of OpenApiRestCall_602466
proc url_ListAccounts_603215(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAccounts_603214(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   user-email: JString
  ##             : User email address with which to filter results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   name: JString
  ##       : Amazon Chime account name prefix with which to filter results.
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Defaults to 100.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603216 = query.getOrDefault("user-email")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "user-email", valid_603216
  var valid_603217 = query.getOrDefault("NextToken")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "NextToken", valid_603217
  var valid_603218 = query.getOrDefault("name")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "name", valid_603218
  var valid_603219 = query.getOrDefault("max-results")
  valid_603219 = validateParameter(valid_603219, JInt, required = false, default = nil)
  if valid_603219 != nil:
    section.add "max-results", valid_603219
  var valid_603220 = query.getOrDefault("next-token")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "next-token", valid_603220
  var valid_603221 = query.getOrDefault("MaxResults")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "MaxResults", valid_603221
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Content-Sha256", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Algorithm")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Algorithm", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Signature")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Signature", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-SignedHeaders", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_ListAccounts_603213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603229, url, valid)

proc call*(call_603230: Call_ListAccounts_603213; userEmail: string = "";
          NextToken: string = ""; name: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAccounts
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ##   userEmail: string
  ##            : User email address with which to filter results.
  ##   NextToken: string
  ##            : Pagination token
  ##   name: string
  ##       : Amazon Chime account name prefix with which to filter results.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Defaults to 100.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603231 = newJObject()
  add(query_603231, "user-email", newJString(userEmail))
  add(query_603231, "NextToken", newJString(NextToken))
  add(query_603231, "name", newJString(name))
  add(query_603231, "max-results", newJInt(maxResults))
  add(query_603231, "next-token", newJString(nextToken))
  add(query_603231, "MaxResults", newJString(MaxResults))
  result = call_603230.call(nil, query_603231, nil, nil, nil)

var listAccounts* = Call_ListAccounts_603213(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_603214, base: "/", url: url_ListAccounts_603215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_603263 = ref object of OpenApiRestCall_602466
proc url_CreateBot_603265(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateBot_603264(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603266 = path.getOrDefault("accountId")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = nil)
  if valid_603266 != nil:
    section.add "accountId", valid_603266
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603267 = header.getOrDefault("X-Amz-Date")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Date", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Content-Sha256", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Algorithm")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Algorithm", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Signature")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Signature", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-SignedHeaders", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Credential")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Credential", valid_603273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603275: Call_CreateBot_603263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_603275.validator(path, query, header, formData, body)
  let scheme = call_603275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603275.url(scheme.get, call_603275.host, call_603275.base,
                         call_603275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603275, url, valid)

proc call*(call_603276: Call_CreateBot_603263; accountId: string; body: JsonNode): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603277 = newJObject()
  var body_603278 = newJObject()
  add(path_603277, "accountId", newJString(accountId))
  if body != nil:
    body_603278 = body
  result = call_603276.call(path_603277, nil, nil, nil, body_603278)

var createBot* = Call_CreateBot_603263(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_603264,
                                    base: "/", url: url_CreateBot_603265,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_603246 = ref object of OpenApiRestCall_602466
proc url_ListBots_603248(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListBots_603247(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603249 = path.getOrDefault("accountId")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "accountId", valid_603249
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Default is 10.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_603250 = query.getOrDefault("max-results")
  valid_603250 = validateParameter(valid_603250, JInt, required = false, default = nil)
  if valid_603250 != nil:
    section.add "max-results", valid_603250
  var valid_603251 = query.getOrDefault("next-token")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "next-token", valid_603251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603252 = header.getOrDefault("X-Amz-Date")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Date", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Security-Token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Security-Token", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Content-Sha256", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Algorithm")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Algorithm", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Signature")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Signature", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-SignedHeaders", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Credential")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Credential", valid_603258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603259: Call_ListBots_603246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_603259.validator(path, query, header, formData, body)
  let scheme = call_603259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603259.url(scheme.get, call_603259.host, call_603259.base,
                         call_603259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603259, url, valid)

proc call*(call_603260: Call_ListBots_603246; accountId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBots
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Default is 10.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_603261 = newJObject()
  var query_603262 = newJObject()
  add(path_603261, "accountId", newJString(accountId))
  add(query_603262, "max-results", newJInt(maxResults))
  add(query_603262, "next-token", newJString(nextToken))
  result = call_603260.call(path_603261, query_603262, nil, nil, nil)

var listBots* = Call_ListBots_603246(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_603247, base: "/",
                                  url: url_ListBots_603248,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_603296 = ref object of OpenApiRestCall_602466
proc url_CreatePhoneNumberOrder_603298(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePhoneNumberOrder_603297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603299 = header.getOrDefault("X-Amz-Date")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Date", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Security-Token")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Security-Token", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Content-Sha256", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Algorithm")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Algorithm", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Signature")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Signature", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-SignedHeaders", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Credential")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Credential", valid_603305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603307: Call_CreatePhoneNumberOrder_603296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_603307.validator(path, query, header, formData, body)
  let scheme = call_603307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603307.url(scheme.get, call_603307.host, call_603307.base,
                         call_603307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603307, url, valid)

proc call*(call_603308: Call_CreatePhoneNumberOrder_603296; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_603309 = newJObject()
  if body != nil:
    body_603309 = body
  result = call_603308.call(nil, nil, nil, nil, body_603309)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_603296(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_603297, base: "/",
    url: url_CreatePhoneNumberOrder_603298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_603279 = ref object of OpenApiRestCall_602466
proc url_ListPhoneNumberOrders_603281(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPhoneNumberOrders_603280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603282 = query.getOrDefault("NextToken")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "NextToken", valid_603282
  var valid_603283 = query.getOrDefault("max-results")
  valid_603283 = validateParameter(valid_603283, JInt, required = false, default = nil)
  if valid_603283 != nil:
    section.add "max-results", valid_603283
  var valid_603284 = query.getOrDefault("next-token")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "next-token", valid_603284
  var valid_603285 = query.getOrDefault("MaxResults")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "MaxResults", valid_603285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603286 = header.getOrDefault("X-Amz-Date")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Date", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Security-Token")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Security-Token", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603293: Call_ListPhoneNumberOrders_603279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_603293.validator(path, query, header, formData, body)
  let scheme = call_603293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603293.url(scheme.get, call_603293.host, call_603293.base,
                         call_603293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603293, url, valid)

proc call*(call_603294: Call_ListPhoneNumberOrders_603279; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPhoneNumberOrders
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603295 = newJObject()
  add(query_603295, "NextToken", newJString(NextToken))
  add(query_603295, "max-results", newJInt(maxResults))
  add(query_603295, "next-token", newJString(nextToken))
  add(query_603295, "MaxResults", newJString(MaxResults))
  result = call_603294.call(nil, query_603295, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_603279(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_603280, base: "/",
    url: url_ListPhoneNumberOrders_603281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_603327 = ref object of OpenApiRestCall_602466
proc url_CreateVoiceConnector_603329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVoiceConnector_603328(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Content-Sha256", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Algorithm")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Algorithm", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Signature")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Signature", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-SignedHeaders", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Credential")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Credential", valid_603336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603338: Call_CreateVoiceConnector_603327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ## 
  let valid = call_603338.validator(path, query, header, formData, body)
  let scheme = call_603338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603338.url(scheme.get, call_603338.host, call_603338.base,
                         call_603338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603338, url, valid)

proc call*(call_603339: Call_CreateVoiceConnector_603327; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ##   body: JObject (required)
  var body_603340 = newJObject()
  if body != nil:
    body_603340 = body
  result = call_603339.call(nil, nil, nil, nil, body_603340)

var createVoiceConnector* = Call_CreateVoiceConnector_603327(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_603328, base: "/",
    url: url_CreateVoiceConnector_603329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_603310 = ref object of OpenApiRestCall_602466
proc url_ListVoiceConnectors_603312(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVoiceConnectors_603311(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603313 = query.getOrDefault("NextToken")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "NextToken", valid_603313
  var valid_603314 = query.getOrDefault("max-results")
  valid_603314 = validateParameter(valid_603314, JInt, required = false, default = nil)
  if valid_603314 != nil:
    section.add "max-results", valid_603314
  var valid_603315 = query.getOrDefault("next-token")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "next-token", valid_603315
  var valid_603316 = query.getOrDefault("MaxResults")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "MaxResults", valid_603316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603317 = header.getOrDefault("X-Amz-Date")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Date", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Security-Token")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Security-Token", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Content-Sha256", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Algorithm")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Algorithm", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Signature")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Signature", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-SignedHeaders", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Credential")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Credential", valid_603323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_ListVoiceConnectors_603310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_ListVoiceConnectors_603310; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listVoiceConnectors
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603326 = newJObject()
  add(query_603326, "NextToken", newJString(NextToken))
  add(query_603326, "max-results", newJInt(maxResults))
  add(query_603326, "next-token", newJString(nextToken))
  add(query_603326, "MaxResults", newJString(MaxResults))
  result = call_603325.call(nil, query_603326, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_603310(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_603311, base: "/",
    url: url_ListVoiceConnectors_603312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_603355 = ref object of OpenApiRestCall_602466
proc url_UpdateAccount_603357(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateAccount_603356(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603358 = path.getOrDefault("accountId")
  valid_603358 = validateParameter(valid_603358, JString, required = true,
                                 default = nil)
  if valid_603358 != nil:
    section.add "accountId", valid_603358
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603359 = header.getOrDefault("X-Amz-Date")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Date", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Security-Token")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Security-Token", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Content-Sha256", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_UpdateAccount_603355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_UpdateAccount_603355; accountId: string; body: JsonNode): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603369 = newJObject()
  var body_603370 = newJObject()
  add(path_603369, "accountId", newJString(accountId))
  if body != nil:
    body_603370 = body
  result = call_603368.call(path_603369, nil, nil, nil, body_603370)

var updateAccount* = Call_UpdateAccount_603355(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_603356,
    base: "/", url: url_UpdateAccount_603357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_603341 = ref object of OpenApiRestCall_602466
proc url_GetAccount_603343(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetAccount_603342(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603344 = path.getOrDefault("accountId")
  valid_603344 = validateParameter(valid_603344, JString, required = true,
                                 default = nil)
  if valid_603344 != nil:
    section.add "accountId", valid_603344
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Content-Sha256", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Algorithm")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Algorithm", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Signature")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Signature", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-SignedHeaders", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Credential")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Credential", valid_603351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603352: Call_GetAccount_603341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_603352.validator(path, query, header, formData, body)
  let scheme = call_603352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603352.url(scheme.get, call_603352.host, call_603352.base,
                         call_603352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603352, url, valid)

proc call*(call_603353: Call_GetAccount_603341; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_603354 = newJObject()
  add(path_603354, "accountId", newJString(accountId))
  result = call_603353.call(path_603354, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_603341(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_603342,
                                      base: "/", url: url_GetAccount_603343,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_603371 = ref object of OpenApiRestCall_602466
proc url_DeleteAccount_603373(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteAccount_603372(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603374 = path.getOrDefault("accountId")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = nil)
  if valid_603374 != nil:
    section.add "accountId", valid_603374
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Content-Sha256", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Algorithm")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Algorithm", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Signature")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Signature", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-SignedHeaders", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Credential")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Credential", valid_603381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603382: Call_DeleteAccount_603371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_603382.validator(path, query, header, formData, body)
  let scheme = call_603382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603382.url(scheme.get, call_603382.host, call_603382.base,
                         call_603382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603382, url, valid)

proc call*(call_603383: Call_DeleteAccount_603371; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_603384 = newJObject()
  add(path_603384, "accountId", newJString(accountId))
  result = call_603383.call(path_603384, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_603371(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_603372,
    base: "/", url: url_DeleteAccount_603373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_603400 = ref object of OpenApiRestCall_602466
proc url_PutEventsConfiguration_603402(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "botId" in path, "`botId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botId"),
               (kind: ConstantSegment, value: "/events-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutEventsConfiguration_603401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   botId: JString (required)
  ##        : The bot ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603403 = path.getOrDefault("accountId")
  valid_603403 = validateParameter(valid_603403, JString, required = true,
                                 default = nil)
  if valid_603403 != nil:
    section.add "accountId", valid_603403
  var valid_603404 = path.getOrDefault("botId")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = nil)
  if valid_603404 != nil:
    section.add "botId", valid_603404
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Content-Sha256", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Algorithm")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Algorithm", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Signature")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Signature", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-SignedHeaders", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Credential")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Credential", valid_603411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603413: Call_PutEventsConfiguration_603400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_603413.validator(path, query, header, formData, body)
  let scheme = call_603413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603413.url(scheme.get, call_603413.host, call_603413.base,
                         call_603413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603413, url, valid)

proc call*(call_603414: Call_PutEventsConfiguration_603400; accountId: string;
          botId: string; body: JsonNode): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_603415 = newJObject()
  var body_603416 = newJObject()
  add(path_603415, "accountId", newJString(accountId))
  add(path_603415, "botId", newJString(botId))
  if body != nil:
    body_603416 = body
  result = call_603414.call(path_603415, nil, nil, nil, body_603416)

var putEventsConfiguration* = Call_PutEventsConfiguration_603400(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_603401, base: "/",
    url: url_PutEventsConfiguration_603402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_603385 = ref object of OpenApiRestCall_602466
proc url_GetEventsConfiguration_603387(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "botId" in path, "`botId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botId"),
               (kind: ConstantSegment, value: "/events-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetEventsConfiguration_603386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   botId: JString (required)
  ##        : The bot ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603388 = path.getOrDefault("accountId")
  valid_603388 = validateParameter(valid_603388, JString, required = true,
                                 default = nil)
  if valid_603388 != nil:
    section.add "accountId", valid_603388
  var valid_603389 = path.getOrDefault("botId")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = nil)
  if valid_603389 != nil:
    section.add "botId", valid_603389
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Content-Sha256", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Algorithm")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Algorithm", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Signature")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Signature", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-SignedHeaders", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Credential")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Credential", valid_603396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603397: Call_GetEventsConfiguration_603385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_603397.validator(path, query, header, formData, body)
  let scheme = call_603397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603397.url(scheme.get, call_603397.host, call_603397.base,
                         call_603397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603397, url, valid)

proc call*(call_603398: Call_GetEventsConfiguration_603385; accountId: string;
          botId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_603399 = newJObject()
  add(path_603399, "accountId", newJString(accountId))
  add(path_603399, "botId", newJString(botId))
  result = call_603398.call(path_603399, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_603385(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_603386, base: "/",
    url: url_GetEventsConfiguration_603387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_603417 = ref object of OpenApiRestCall_602466
proc url_DeleteEventsConfiguration_603419(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "botId" in path, "`botId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botId"),
               (kind: ConstantSegment, value: "/events-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteEventsConfiguration_603418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   botId: JString (required)
  ##        : The bot ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603420 = path.getOrDefault("accountId")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = nil)
  if valid_603420 != nil:
    section.add "accountId", valid_603420
  var valid_603421 = path.getOrDefault("botId")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = nil)
  if valid_603421 != nil:
    section.add "botId", valid_603421
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_DeleteEventsConfiguration_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_DeleteEventsConfiguration_603417; accountId: string;
          botId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_603431 = newJObject()
  add(path_603431, "accountId", newJString(accountId))
  add(path_603431, "botId", newJString(botId))
  result = call_603430.call(path_603431, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_603417(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_603418, base: "/",
    url: url_DeleteEventsConfiguration_603419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_603446 = ref object of OpenApiRestCall_602466
proc url_UpdatePhoneNumber_603448(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdatePhoneNumber_603447(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   phoneNumberId: JString (required)
  ##                : The phone number ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `phoneNumberId` field"
  var valid_603449 = path.getOrDefault("phoneNumberId")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = nil)
  if valid_603449 != nil:
    section.add "phoneNumberId", valid_603449
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Content-Sha256", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Algorithm")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Algorithm", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Signature")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Signature", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-SignedHeaders", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Credential")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Credential", valid_603456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603458: Call_UpdatePhoneNumber_603446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_603458.validator(path, query, header, formData, body)
  let scheme = call_603458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603458.url(scheme.get, call_603458.host, call_603458.base,
                         call_603458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603458, url, valid)

proc call*(call_603459: Call_UpdatePhoneNumber_603446; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_603460 = newJObject()
  var body_603461 = newJObject()
  add(path_603460, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_603461 = body
  result = call_603459.call(path_603460, nil, nil, nil, body_603461)

var updatePhoneNumber* = Call_UpdatePhoneNumber_603446(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_603447, base: "/",
    url: url_UpdatePhoneNumber_603448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_603432 = ref object of OpenApiRestCall_602466
proc url_GetPhoneNumber_603434(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetPhoneNumber_603433(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   phoneNumberId: JString (required)
  ##                : The phone number ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `phoneNumberId` field"
  var valid_603435 = path.getOrDefault("phoneNumberId")
  valid_603435 = validateParameter(valid_603435, JString, required = true,
                                 default = nil)
  if valid_603435 != nil:
    section.add "phoneNumberId", valid_603435
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603436 = header.getOrDefault("X-Amz-Date")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Date", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Security-Token")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Security-Token", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603443: Call_GetPhoneNumber_603432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_603443.validator(path, query, header, formData, body)
  let scheme = call_603443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603443.url(scheme.get, call_603443.host, call_603443.base,
                         call_603443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603443, url, valid)

proc call*(call_603444: Call_GetPhoneNumber_603432; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_603445 = newJObject()
  add(path_603445, "phoneNumberId", newJString(phoneNumberId))
  result = call_603444.call(path_603445, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_603432(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_603433,
    base: "/", url: url_GetPhoneNumber_603434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_603462 = ref object of OpenApiRestCall_602466
proc url_DeletePhoneNumber_603464(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeletePhoneNumber_603463(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   phoneNumberId: JString (required)
  ##                : The phone number ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `phoneNumberId` field"
  var valid_603465 = path.getOrDefault("phoneNumberId")
  valid_603465 = validateParameter(valid_603465, JString, required = true,
                                 default = nil)
  if valid_603465 != nil:
    section.add "phoneNumberId", valid_603465
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603466 = header.getOrDefault("X-Amz-Date")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Date", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Security-Token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Security-Token", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603473: Call_DeletePhoneNumber_603462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_603473.validator(path, query, header, formData, body)
  let scheme = call_603473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603473.url(scheme.get, call_603473.host, call_603473.base,
                         call_603473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603473, url, valid)

proc call*(call_603474: Call_DeletePhoneNumber_603462; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_603475 = newJObject()
  add(path_603475, "phoneNumberId", newJString(phoneNumberId))
  result = call_603474.call(path_603475, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_603462(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_603463, base: "/",
    url: url_DeletePhoneNumber_603464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_603490 = ref object of OpenApiRestCall_602466
proc url_UpdateVoiceConnector_603492(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateVoiceConnector_603491(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603493 = path.getOrDefault("voiceConnectorId")
  valid_603493 = validateParameter(valid_603493, JString, required = true,
                                 default = nil)
  if valid_603493 != nil:
    section.add "voiceConnectorId", valid_603493
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603494 = header.getOrDefault("X-Amz-Date")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Date", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Security-Token")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Security-Token", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Content-Sha256", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Algorithm")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Algorithm", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Signature")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Signature", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-SignedHeaders", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Credential")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Credential", valid_603500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603502: Call_UpdateVoiceConnector_603490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603502.validator(path, query, header, formData, body)
  let scheme = call_603502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603502.url(scheme.get, call_603502.host, call_603502.base,
                         call_603502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603502, url, valid)

proc call*(call_603503: Call_UpdateVoiceConnector_603490; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_603504 = newJObject()
  var body_603505 = newJObject()
  add(path_603504, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_603505 = body
  result = call_603503.call(path_603504, nil, nil, nil, body_603505)

var updateVoiceConnector* = Call_UpdateVoiceConnector_603490(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_603491, base: "/",
    url: url_UpdateVoiceConnector_603492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_603476 = ref object of OpenApiRestCall_602466
proc url_GetVoiceConnector_603478(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetVoiceConnector_603477(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603479 = path.getOrDefault("voiceConnectorId")
  valid_603479 = validateParameter(valid_603479, JString, required = true,
                                 default = nil)
  if valid_603479 != nil:
    section.add "voiceConnectorId", valid_603479
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603480 = header.getOrDefault("X-Amz-Date")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Date", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Security-Token")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Security-Token", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Content-Sha256", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Algorithm")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Algorithm", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Signature")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Signature", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-SignedHeaders", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Credential")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Credential", valid_603486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603487: Call_GetVoiceConnector_603476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_603487.validator(path, query, header, formData, body)
  let scheme = call_603487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603487.url(scheme.get, call_603487.host, call_603487.base,
                         call_603487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603487, url, valid)

proc call*(call_603488: Call_GetVoiceConnector_603476; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603489 = newJObject()
  add(path_603489, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603488.call(path_603489, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_603476(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_603477, base: "/",
    url: url_GetVoiceConnector_603478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_603506 = ref object of OpenApiRestCall_602466
proc url_DeleteVoiceConnector_603508(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVoiceConnector_603507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603509 = path.getOrDefault("voiceConnectorId")
  valid_603509 = validateParameter(valid_603509, JString, required = true,
                                 default = nil)
  if valid_603509 != nil:
    section.add "voiceConnectorId", valid_603509
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603510 = header.getOrDefault("X-Amz-Date")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Date", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Security-Token")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Security-Token", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Content-Sha256", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Algorithm")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Algorithm", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Signature")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Signature", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-SignedHeaders", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Credential")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Credential", valid_603516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603517: Call_DeleteVoiceConnector_603506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ## 
  let valid = call_603517.validator(path, query, header, formData, body)
  let scheme = call_603517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603517.url(scheme.get, call_603517.host, call_603517.base,
                         call_603517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603517, url, valid)

proc call*(call_603518: Call_DeleteVoiceConnector_603506; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603519 = newJObject()
  add(path_603519, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603518.call(path_603519, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_603506(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_603507, base: "/",
    url: url_DeleteVoiceConnector_603508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_603534 = ref object of OpenApiRestCall_602466
proc url_PutVoiceConnectorOrigination_603536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/origination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutVoiceConnectorOrigination_603535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603537 = path.getOrDefault("voiceConnectorId")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = nil)
  if valid_603537 != nil:
    section.add "voiceConnectorId", valid_603537
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603538 = header.getOrDefault("X-Amz-Date")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Date", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Security-Token")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Security-Token", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Content-Sha256", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Algorithm")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Algorithm", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Signature")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Signature", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-SignedHeaders", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Credential")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Credential", valid_603544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603546: Call_PutVoiceConnectorOrigination_603534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603546.validator(path, query, header, formData, body)
  let scheme = call_603546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603546.url(scheme.get, call_603546.host, call_603546.base,
                         call_603546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603546, url, valid)

proc call*(call_603547: Call_PutVoiceConnectorOrigination_603534;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_603548 = newJObject()
  var body_603549 = newJObject()
  add(path_603548, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_603549 = body
  result = call_603547.call(path_603548, nil, nil, nil, body_603549)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_603534(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_603535, base: "/",
    url: url_PutVoiceConnectorOrigination_603536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_603520 = ref object of OpenApiRestCall_602466
proc url_GetVoiceConnectorOrigination_603522(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/origination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetVoiceConnectorOrigination_603521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603523 = path.getOrDefault("voiceConnectorId")
  valid_603523 = validateParameter(valid_603523, JString, required = true,
                                 default = nil)
  if valid_603523 != nil:
    section.add "voiceConnectorId", valid_603523
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603524 = header.getOrDefault("X-Amz-Date")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Date", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Security-Token")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Security-Token", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Content-Sha256", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Algorithm")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Algorithm", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Signature")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Signature", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-SignedHeaders", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Credential")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Credential", valid_603530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603531: Call_GetVoiceConnectorOrigination_603520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603531.validator(path, query, header, formData, body)
  let scheme = call_603531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603531.url(scheme.get, call_603531.host, call_603531.base,
                         call_603531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603531, url, valid)

proc call*(call_603532: Call_GetVoiceConnectorOrigination_603520;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603533 = newJObject()
  add(path_603533, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603532.call(path_603533, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_603520(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_603521, base: "/",
    url: url_GetVoiceConnectorOrigination_603522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_603550 = ref object of OpenApiRestCall_602466
proc url_DeleteVoiceConnectorOrigination_603552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/origination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorOrigination_603551(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603553 = path.getOrDefault("voiceConnectorId")
  valid_603553 = validateParameter(valid_603553, JString, required = true,
                                 default = nil)
  if valid_603553 != nil:
    section.add "voiceConnectorId", valid_603553
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603554 = header.getOrDefault("X-Amz-Date")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Date", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Security-Token")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Security-Token", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Content-Sha256", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Algorithm")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Algorithm", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Signature")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Signature", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-SignedHeaders", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Credential")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Credential", valid_603560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603561: Call_DeleteVoiceConnectorOrigination_603550;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603561.validator(path, query, header, formData, body)
  let scheme = call_603561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603561.url(scheme.get, call_603561.host, call_603561.base,
                         call_603561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603561, url, valid)

proc call*(call_603562: Call_DeleteVoiceConnectorOrigination_603550;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603563 = newJObject()
  add(path_603563, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603562.call(path_603563, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_603550(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_603551, base: "/",
    url: url_DeleteVoiceConnectorOrigination_603552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_603578 = ref object of OpenApiRestCall_602466
proc url_PutVoiceConnectorTermination_603580(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/termination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutVoiceConnectorTermination_603579(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603581 = path.getOrDefault("voiceConnectorId")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = nil)
  if valid_603581 != nil:
    section.add "voiceConnectorId", valid_603581
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603582 = header.getOrDefault("X-Amz-Date")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Date", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Security-Token")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Security-Token", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Content-Sha256", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Algorithm")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Algorithm", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-SignedHeaders", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Credential")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Credential", valid_603588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603590: Call_PutVoiceConnectorTermination_603578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603590.validator(path, query, header, formData, body)
  let scheme = call_603590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603590.url(scheme.get, call_603590.host, call_603590.base,
                         call_603590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603590, url, valid)

proc call*(call_603591: Call_PutVoiceConnectorTermination_603578;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_603592 = newJObject()
  var body_603593 = newJObject()
  add(path_603592, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_603593 = body
  result = call_603591.call(path_603592, nil, nil, nil, body_603593)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_603578(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_603579, base: "/",
    url: url_PutVoiceConnectorTermination_603580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_603564 = ref object of OpenApiRestCall_602466
proc url_GetVoiceConnectorTermination_603566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/termination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetVoiceConnectorTermination_603565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603567 = path.getOrDefault("voiceConnectorId")
  valid_603567 = validateParameter(valid_603567, JString, required = true,
                                 default = nil)
  if valid_603567 != nil:
    section.add "voiceConnectorId", valid_603567
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603568 = header.getOrDefault("X-Amz-Date")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Date", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Security-Token")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Security-Token", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Content-Sha256", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Algorithm")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Algorithm", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Signature")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Signature", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-SignedHeaders", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Credential")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Credential", valid_603574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603575: Call_GetVoiceConnectorTermination_603564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603575.validator(path, query, header, formData, body)
  let scheme = call_603575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603575.url(scheme.get, call_603575.host, call_603575.base,
                         call_603575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603575, url, valid)

proc call*(call_603576: Call_GetVoiceConnectorTermination_603564;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603577 = newJObject()
  add(path_603577, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603576.call(path_603577, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_603564(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_603565, base: "/",
    url: url_GetVoiceConnectorTermination_603566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_603594 = ref object of OpenApiRestCall_602466
proc url_DeleteVoiceConnectorTermination_603596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/termination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorTermination_603595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603597 = path.getOrDefault("voiceConnectorId")
  valid_603597 = validateParameter(valid_603597, JString, required = true,
                                 default = nil)
  if valid_603597 != nil:
    section.add "voiceConnectorId", valid_603597
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603598 = header.getOrDefault("X-Amz-Date")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Date", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Security-Token")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Security-Token", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Content-Sha256", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Algorithm")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Algorithm", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Signature")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Signature", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-SignedHeaders", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Credential")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Credential", valid_603604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603605: Call_DeleteVoiceConnectorTermination_603594;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603605.validator(path, query, header, formData, body)
  let scheme = call_603605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603605.url(scheme.get, call_603605.host, call_603605.base,
                         call_603605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603605, url, valid)

proc call*(call_603606: Call_DeleteVoiceConnectorTermination_603594;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603607 = newJObject()
  add(path_603607, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603606.call(path_603607, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_603594(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_603595, base: "/",
    url: url_DeleteVoiceConnectorTermination_603596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_603608 = ref object of OpenApiRestCall_602466
proc url_DeleteVoiceConnectorTerminationCredentials_603610(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"), (
        kind: ConstantSegment, value: "/termination/credentials#operation=delete")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorTerminationCredentials_603609(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603611 = path.getOrDefault("voiceConnectorId")
  valid_603611 = validateParameter(valid_603611, JString, required = true,
                                 default = nil)
  if valid_603611 != nil:
    section.add "voiceConnectorId", valid_603611
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603612 = query.getOrDefault("operation")
  valid_603612 = validateParameter(valid_603612, JString, required = true,
                                 default = newJString("delete"))
  if valid_603612 != nil:
    section.add "operation", valid_603612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603613 = header.getOrDefault("X-Amz-Date")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Date", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Security-Token")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Security-Token", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Content-Sha256", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Algorithm")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Algorithm", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Signature")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Signature", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-SignedHeaders", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Credential")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Credential", valid_603619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603621: Call_DeleteVoiceConnectorTerminationCredentials_603608;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_603621.validator(path, query, header, formData, body)
  let scheme = call_603621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603621.url(scheme.get, call_603621.host, call_603621.base,
                         call_603621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603621, url, valid)

proc call*(call_603622: Call_DeleteVoiceConnectorTerminationCredentials_603608;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603623 = newJObject()
  var query_603624 = newJObject()
  var body_603625 = newJObject()
  add(path_603623, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603624, "operation", newJString(operation))
  if body != nil:
    body_603625 = body
  result = call_603622.call(path_603623, query_603624, nil, nil, body_603625)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_603608(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_603609,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_603610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_603626 = ref object of OpenApiRestCall_602466
proc url_DisassociatePhoneNumberFromUser_603628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId"), (kind: ConstantSegment,
        value: "#operation=disassociate-phone-number")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DisassociatePhoneNumberFromUser_603627(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603629 = path.getOrDefault("accountId")
  valid_603629 = validateParameter(valid_603629, JString, required = true,
                                 default = nil)
  if valid_603629 != nil:
    section.add "accountId", valid_603629
  var valid_603630 = path.getOrDefault("userId")
  valid_603630 = validateParameter(valid_603630, JString, required = true,
                                 default = nil)
  if valid_603630 != nil:
    section.add "userId", valid_603630
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603631 = query.getOrDefault("operation")
  valid_603631 = validateParameter(valid_603631, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_603631 != nil:
    section.add "operation", valid_603631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603632 = header.getOrDefault("X-Amz-Date")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Date", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Security-Token")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Security-Token", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Content-Sha256", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Algorithm")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Algorithm", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Signature")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Signature", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-SignedHeaders", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Credential")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Credential", valid_603638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_DisassociatePhoneNumberFromUser_603626;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_DisassociatePhoneNumberFromUser_603626;
          accountId: string; userId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603641 = newJObject()
  var query_603642 = newJObject()
  add(path_603641, "accountId", newJString(accountId))
  add(query_603642, "operation", newJString(operation))
  add(path_603641, "userId", newJString(userId))
  result = call_603640.call(path_603641, query_603642, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_603626(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_603627, base: "/",
    url: url_DisassociatePhoneNumberFromUser_603628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_603643 = ref object of OpenApiRestCall_602466
proc url_DisassociatePhoneNumbersFromVoiceConnector_603645(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"), (
        kind: ConstantSegment, value: "#operation=disassociate-phone-numbers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DisassociatePhoneNumbersFromVoiceConnector_603644(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603646 = path.getOrDefault("voiceConnectorId")
  valid_603646 = validateParameter(valid_603646, JString, required = true,
                                 default = nil)
  if valid_603646 != nil:
    section.add "voiceConnectorId", valid_603646
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603647 = query.getOrDefault("operation")
  valid_603647 = validateParameter(valid_603647, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_603647 != nil:
    section.add "operation", valid_603647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603648 = header.getOrDefault("X-Amz-Date")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Date", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Security-Token")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Security-Token", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Content-Sha256", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Algorithm")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Algorithm", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Signature")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Signature", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-SignedHeaders", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Credential")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Credential", valid_603654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603656: Call_DisassociatePhoneNumbersFromVoiceConnector_603643;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603656.validator(path, query, header, formData, body)
  let scheme = call_603656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603656.url(scheme.get, call_603656.host, call_603656.base,
                         call_603656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603656, url, valid)

proc call*(call_603657: Call_DisassociatePhoneNumbersFromVoiceConnector_603643;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603658 = newJObject()
  var query_603659 = newJObject()
  var body_603660 = newJObject()
  add(path_603658, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603659, "operation", newJString(operation))
  if body != nil:
    body_603660 = body
  result = call_603657.call(path_603658, query_603659, nil, nil, body_603660)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_603643(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_603644,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_603645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_603675 = ref object of OpenApiRestCall_602466
proc url_UpdateAccountSettings_603677(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateAccountSettings_603676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603678 = path.getOrDefault("accountId")
  valid_603678 = validateParameter(valid_603678, JString, required = true,
                                 default = nil)
  if valid_603678 != nil:
    section.add "accountId", valid_603678
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603679 = header.getOrDefault("X-Amz-Date")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Date", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Security-Token")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Security-Token", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Content-Sha256", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Algorithm")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Algorithm", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Signature")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Signature", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-SignedHeaders", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Credential")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Credential", valid_603685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603687: Call_UpdateAccountSettings_603675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_603687.validator(path, query, header, formData, body)
  let scheme = call_603687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603687.url(scheme.get, call_603687.host, call_603687.base,
                         call_603687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603687, url, valid)

proc call*(call_603688: Call_UpdateAccountSettings_603675; accountId: string;
          body: JsonNode): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603689 = newJObject()
  var body_603690 = newJObject()
  add(path_603689, "accountId", newJString(accountId))
  if body != nil:
    body_603690 = body
  result = call_603688.call(path_603689, nil, nil, nil, body_603690)

var updateAccountSettings* = Call_UpdateAccountSettings_603675(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_603676, base: "/",
    url: url_UpdateAccountSettings_603677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_603661 = ref object of OpenApiRestCall_602466
proc url_GetAccountSettings_603663(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetAccountSettings_603662(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603664 = path.getOrDefault("accountId")
  valid_603664 = validateParameter(valid_603664, JString, required = true,
                                 default = nil)
  if valid_603664 != nil:
    section.add "accountId", valid_603664
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603665 = header.getOrDefault("X-Amz-Date")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Date", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Security-Token")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Security-Token", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Content-Sha256", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Algorithm")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Algorithm", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Signature")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Signature", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-SignedHeaders", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Credential")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Credential", valid_603671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603672: Call_GetAccountSettings_603661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_603672.validator(path, query, header, formData, body)
  let scheme = call_603672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603672.url(scheme.get, call_603672.host, call_603672.base,
                         call_603672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603672, url, valid)

proc call*(call_603673: Call_GetAccountSettings_603661; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_603674 = newJObject()
  add(path_603674, "accountId", newJString(accountId))
  result = call_603673.call(path_603674, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_603661(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_603662, base: "/",
    url: url_GetAccountSettings_603663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_603706 = ref object of OpenApiRestCall_602466
proc url_UpdateBot_603708(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "botId" in path, "`botId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateBot_603707(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   botId: JString (required)
  ##        : The bot ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603709 = path.getOrDefault("accountId")
  valid_603709 = validateParameter(valid_603709, JString, required = true,
                                 default = nil)
  if valid_603709 != nil:
    section.add "accountId", valid_603709
  var valid_603710 = path.getOrDefault("botId")
  valid_603710 = validateParameter(valid_603710, JString, required = true,
                                 default = nil)
  if valid_603710 != nil:
    section.add "botId", valid_603710
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603711 = header.getOrDefault("X-Amz-Date")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Date", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Security-Token")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Security-Token", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Content-Sha256", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Algorithm")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Algorithm", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Signature")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Signature", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-SignedHeaders", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Credential")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Credential", valid_603717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603719: Call_UpdateBot_603706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_603719.validator(path, query, header, formData, body)
  let scheme = call_603719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603719.url(scheme.get, call_603719.host, call_603719.base,
                         call_603719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603719, url, valid)

proc call*(call_603720: Call_UpdateBot_603706; accountId: string; botId: string;
          body: JsonNode): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_603721 = newJObject()
  var body_603722 = newJObject()
  add(path_603721, "accountId", newJString(accountId))
  add(path_603721, "botId", newJString(botId))
  if body != nil:
    body_603722 = body
  result = call_603720.call(path_603721, nil, nil, nil, body_603722)

var updateBot* = Call_UpdateBot_603706(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_603707,
                                    base: "/", url: url_UpdateBot_603708,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_603691 = ref object of OpenApiRestCall_602466
proc url_GetBot_603693(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "botId" in path, "`botId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBot_603692(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   botId: JString (required)
  ##        : The bot ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603694 = path.getOrDefault("accountId")
  valid_603694 = validateParameter(valid_603694, JString, required = true,
                                 default = nil)
  if valid_603694 != nil:
    section.add "accountId", valid_603694
  var valid_603695 = path.getOrDefault("botId")
  valid_603695 = validateParameter(valid_603695, JString, required = true,
                                 default = nil)
  if valid_603695 != nil:
    section.add "botId", valid_603695
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603696 = header.getOrDefault("X-Amz-Date")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Date", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Security-Token")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Security-Token", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Content-Sha256", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Algorithm")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Algorithm", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Signature")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Signature", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-SignedHeaders", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Credential")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Credential", valid_603702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603703: Call_GetBot_603691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_603703.validator(path, query, header, formData, body)
  let scheme = call_603703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603703.url(scheme.get, call_603703.host, call_603703.base,
                         call_603703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603703, url, valid)

proc call*(call_603704: Call_GetBot_603691; accountId: string; botId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_603705 = newJObject()
  add(path_603705, "accountId", newJString(accountId))
  add(path_603705, "botId", newJString(botId))
  result = call_603704.call(path_603705, nil, nil, nil, nil)

var getBot* = Call_GetBot_603691(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_603692, base: "/",
                              url: url_GetBot_603693,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_603735 = ref object of OpenApiRestCall_602466
proc url_UpdateGlobalSettings_603737(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGlobalSettings_603736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603738 = header.getOrDefault("X-Amz-Date")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Date", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Security-Token")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Security-Token", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Content-Sha256", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Algorithm")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Algorithm", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Signature")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Signature", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-SignedHeaders", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Credential")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Credential", valid_603744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603746: Call_UpdateGlobalSettings_603735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_603746.validator(path, query, header, formData, body)
  let scheme = call_603746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603746.url(scheme.get, call_603746.host, call_603746.base,
                         call_603746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603746, url, valid)

proc call*(call_603747: Call_UpdateGlobalSettings_603735; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_603748 = newJObject()
  if body != nil:
    body_603748 = body
  result = call_603747.call(nil, nil, nil, nil, body_603748)

var updateGlobalSettings* = Call_UpdateGlobalSettings_603735(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_603736, base: "/",
    url: url_UpdateGlobalSettings_603737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_603723 = ref object of OpenApiRestCall_602466
proc url_GetGlobalSettings_603725(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGlobalSettings_603724(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603726 = header.getOrDefault("X-Amz-Date")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Date", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Security-Token")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Security-Token", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Content-Sha256", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Algorithm")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Algorithm", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Signature")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Signature", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-SignedHeaders", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Credential")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Credential", valid_603732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603733: Call_GetGlobalSettings_603723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_603733.validator(path, query, header, formData, body)
  let scheme = call_603733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603733.url(scheme.get, call_603733.host, call_603733.base,
                         call_603733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603733, url, valid)

proc call*(call_603734: Call_GetGlobalSettings_603723): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_603734.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_603723(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_603724, base: "/",
    url: url_GetGlobalSettings_603725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_603749 = ref object of OpenApiRestCall_602466
proc url_GetPhoneNumberOrder_603751(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "phoneNumberOrderId" in path,
        "`phoneNumberOrderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-number-orders/"),
               (kind: VariableSegment, value: "phoneNumberOrderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetPhoneNumberOrder_603750(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   phoneNumberOrderId: JString (required)
  ##                     : The ID for the phone number order.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `phoneNumberOrderId` field"
  var valid_603752 = path.getOrDefault("phoneNumberOrderId")
  valid_603752 = validateParameter(valid_603752, JString, required = true,
                                 default = nil)
  if valid_603752 != nil:
    section.add "phoneNumberOrderId", valid_603752
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603753 = header.getOrDefault("X-Amz-Date")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Date", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Security-Token")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Security-Token", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Content-Sha256", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-Algorithm")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Algorithm", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Signature")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Signature", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-SignedHeaders", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Credential")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Credential", valid_603759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603760: Call_GetPhoneNumberOrder_603749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_603760.validator(path, query, header, formData, body)
  let scheme = call_603760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603760.url(scheme.get, call_603760.host, call_603760.base,
                         call_603760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603760, url, valid)

proc call*(call_603761: Call_GetPhoneNumberOrder_603749; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_603762 = newJObject()
  add(path_603762, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_603761.call(path_603762, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_603749(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_603750, base: "/",
    url: url_GetPhoneNumberOrder_603751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_603778 = ref object of OpenApiRestCall_602466
proc url_UpdateUser_603780(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateUser_603779(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603781 = path.getOrDefault("accountId")
  valid_603781 = validateParameter(valid_603781, JString, required = true,
                                 default = nil)
  if valid_603781 != nil:
    section.add "accountId", valid_603781
  var valid_603782 = path.getOrDefault("userId")
  valid_603782 = validateParameter(valid_603782, JString, required = true,
                                 default = nil)
  if valid_603782 != nil:
    section.add "userId", valid_603782
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603783 = header.getOrDefault("X-Amz-Date")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Date", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Security-Token")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Security-Token", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Content-Sha256", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Algorithm")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Algorithm", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Signature")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Signature", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-SignedHeaders", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Credential")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Credential", valid_603789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603791: Call_UpdateUser_603778; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_603791.validator(path, query, header, formData, body)
  let scheme = call_603791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603791.url(scheme.get, call_603791.host, call_603791.base,
                         call_603791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603791, url, valid)

proc call*(call_603792: Call_UpdateUser_603778; accountId: string; body: JsonNode;
          userId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603793 = newJObject()
  var body_603794 = newJObject()
  add(path_603793, "accountId", newJString(accountId))
  if body != nil:
    body_603794 = body
  add(path_603793, "userId", newJString(userId))
  result = call_603792.call(path_603793, nil, nil, nil, body_603794)

var updateUser* = Call_UpdateUser_603778(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_603779,
                                      base: "/", url: url_UpdateUser_603780,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_603763 = ref object of OpenApiRestCall_602466
proc url_GetUser_603765(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetUser_603764(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603766 = path.getOrDefault("accountId")
  valid_603766 = validateParameter(valid_603766, JString, required = true,
                                 default = nil)
  if valid_603766 != nil:
    section.add "accountId", valid_603766
  var valid_603767 = path.getOrDefault("userId")
  valid_603767 = validateParameter(valid_603767, JString, required = true,
                                 default = nil)
  if valid_603767 != nil:
    section.add "userId", valid_603767
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603768 = header.getOrDefault("X-Amz-Date")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Date", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Security-Token")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Security-Token", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Content-Sha256", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-Algorithm")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Algorithm", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Signature")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Signature", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-SignedHeaders", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Credential")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Credential", valid_603774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603775: Call_GetUser_603763; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_603775.validator(path, query, header, formData, body)
  let scheme = call_603775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603775.url(scheme.get, call_603775.host, call_603775.base,
                         call_603775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603775, url, valid)

proc call*(call_603776: Call_GetUser_603763; accountId: string; userId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_603777 = newJObject()
  add(path_603777, "accountId", newJString(accountId))
  add(path_603777, "userId", newJString(userId))
  result = call_603776.call(path_603777, nil, nil, nil, nil)

var getUser* = Call_GetUser_603763(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_603764, base: "/",
                                url: url_GetUser_603765,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_603810 = ref object of OpenApiRestCall_602466
proc url_UpdateUserSettings_603812(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateUserSettings_603811(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603813 = path.getOrDefault("accountId")
  valid_603813 = validateParameter(valid_603813, JString, required = true,
                                 default = nil)
  if valid_603813 != nil:
    section.add "accountId", valid_603813
  var valid_603814 = path.getOrDefault("userId")
  valid_603814 = validateParameter(valid_603814, JString, required = true,
                                 default = nil)
  if valid_603814 != nil:
    section.add "userId", valid_603814
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603815 = header.getOrDefault("X-Amz-Date")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Date", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Security-Token")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Security-Token", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Content-Sha256", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Algorithm")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Algorithm", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Signature")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Signature", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-SignedHeaders", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Credential")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Credential", valid_603821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603823: Call_UpdateUserSettings_603810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_603823.validator(path, query, header, formData, body)
  let scheme = call_603823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603823.url(scheme.get, call_603823.host, call_603823.base,
                         call_603823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603823, url, valid)

proc call*(call_603824: Call_UpdateUserSettings_603810; accountId: string;
          body: JsonNode; userId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603825 = newJObject()
  var body_603826 = newJObject()
  add(path_603825, "accountId", newJString(accountId))
  if body != nil:
    body_603826 = body
  add(path_603825, "userId", newJString(userId))
  result = call_603824.call(path_603825, nil, nil, nil, body_603826)

var updateUserSettings* = Call_UpdateUserSettings_603810(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_603811, base: "/",
    url: url_UpdateUserSettings_603812, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_603795 = ref object of OpenApiRestCall_602466
proc url_GetUserSettings_603797(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetUserSettings_603796(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603798 = path.getOrDefault("accountId")
  valid_603798 = validateParameter(valid_603798, JString, required = true,
                                 default = nil)
  if valid_603798 != nil:
    section.add "accountId", valid_603798
  var valid_603799 = path.getOrDefault("userId")
  valid_603799 = validateParameter(valid_603799, JString, required = true,
                                 default = nil)
  if valid_603799 != nil:
    section.add "userId", valid_603799
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603800 = header.getOrDefault("X-Amz-Date")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Date", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Security-Token")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Security-Token", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Content-Sha256", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Algorithm")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Algorithm", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Signature")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Signature", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-SignedHeaders", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Credential")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Credential", valid_603806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603807: Call_GetUserSettings_603795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_603807.validator(path, query, header, formData, body)
  let scheme = call_603807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603807.url(scheme.get, call_603807.host, call_603807.base,
                         call_603807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603807, url, valid)

proc call*(call_603808: Call_GetUserSettings_603795; accountId: string;
          userId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_603809 = newJObject()
  add(path_603809, "accountId", newJString(accountId))
  add(path_603809, "userId", newJString(userId))
  result = call_603808.call(path_603809, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_603795(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_603796, base: "/", url: url_GetUserSettings_603797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_603827 = ref object of OpenApiRestCall_602466
proc url_GetVoiceConnectorTerminationHealth_603829(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/termination/health")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetVoiceConnectorTerminationHealth_603828(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603830 = path.getOrDefault("voiceConnectorId")
  valid_603830 = validateParameter(valid_603830, JString, required = true,
                                 default = nil)
  if valid_603830 != nil:
    section.add "voiceConnectorId", valid_603830
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603831 = header.getOrDefault("X-Amz-Date")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Date", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Security-Token")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Security-Token", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Content-Sha256", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Algorithm")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Algorithm", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Signature")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Signature", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-SignedHeaders", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Credential")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Credential", valid_603837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603838: Call_GetVoiceConnectorTerminationHealth_603827;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603838.validator(path, query, header, formData, body)
  let scheme = call_603838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603838.url(scheme.get, call_603838.host, call_603838.base,
                         call_603838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603838, url, valid)

proc call*(call_603839: Call_GetVoiceConnectorTerminationHealth_603827;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603840 = newJObject()
  add(path_603840, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603839.call(path_603840, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_603827(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_603828, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_603829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_603841 = ref object of OpenApiRestCall_602466
proc url_InviteUsers_603843(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users#operation=add")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_InviteUsers_603842(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603844 = path.getOrDefault("accountId")
  valid_603844 = validateParameter(valid_603844, JString, required = true,
                                 default = nil)
  if valid_603844 != nil:
    section.add "accountId", valid_603844
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603845 = query.getOrDefault("operation")
  valid_603845 = validateParameter(valid_603845, JString, required = true,
                                 default = newJString("add"))
  if valid_603845 != nil:
    section.add "operation", valid_603845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603846 = header.getOrDefault("X-Amz-Date")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-Date", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Security-Token")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Security-Token", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Content-Sha256", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Algorithm")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Algorithm", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Signature")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Signature", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-SignedHeaders", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Credential")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Credential", valid_603852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603854: Call_InviteUsers_603841; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_603854.validator(path, query, header, formData, body)
  let scheme = call_603854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603854.url(scheme.get, call_603854.host, call_603854.base,
                         call_603854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603854, url, valid)

proc call*(call_603855: Call_InviteUsers_603841; accountId: string; body: JsonNode;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603856 = newJObject()
  var query_603857 = newJObject()
  var body_603858 = newJObject()
  add(path_603856, "accountId", newJString(accountId))
  add(query_603857, "operation", newJString(operation))
  if body != nil:
    body_603858 = body
  result = call_603855.call(path_603856, query_603857, nil, nil, body_603858)

var inviteUsers* = Call_InviteUsers_603841(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_603842,
                                        base: "/", url: url_InviteUsers_603843,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_603859 = ref object of OpenApiRestCall_602466
proc url_ListPhoneNumbers_603861(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPhoneNumbers_603860(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   filter-name: JString
  ##              : The filter to use to limit the number of results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   filter-value: JString
  ##               : The value to use for the filter.
  ##   status: JString
  ##         : The phone number status.
  ##   product-type: JString
  ##               : The phone number product type.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603862 = query.getOrDefault("filter-name")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_603862 != nil:
    section.add "filter-name", valid_603862
  var valid_603863 = query.getOrDefault("NextToken")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "NextToken", valid_603863
  var valid_603864 = query.getOrDefault("max-results")
  valid_603864 = validateParameter(valid_603864, JInt, required = false, default = nil)
  if valid_603864 != nil:
    section.add "max-results", valid_603864
  var valid_603865 = query.getOrDefault("filter-value")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "filter-value", valid_603865
  var valid_603866 = query.getOrDefault("status")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_603866 != nil:
    section.add "status", valid_603866
  var valid_603867 = query.getOrDefault("product-type")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_603867 != nil:
    section.add "product-type", valid_603867
  var valid_603868 = query.getOrDefault("next-token")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "next-token", valid_603868
  var valid_603869 = query.getOrDefault("MaxResults")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "MaxResults", valid_603869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603870 = header.getOrDefault("X-Amz-Date")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Date", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Security-Token")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Security-Token", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Content-Sha256", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Algorithm")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Algorithm", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Signature")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Signature", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-SignedHeaders", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Credential")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Credential", valid_603876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603877: Call_ListPhoneNumbers_603859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
  ## 
  let valid = call_603877.validator(path, query, header, formData, body)
  let scheme = call_603877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603877.url(scheme.get, call_603877.host, call_603877.base,
                         call_603877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603877, url, valid)

proc call*(call_603878: Call_ListPhoneNumbers_603859;
          filterName: string = "AccountId"; NextToken: string = ""; maxResults: int = 0;
          filterValue: string = ""; status: string = "AcquireInProgress";
          productType: string = "BusinessCalling"; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listPhoneNumbers
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
  ##   filterName: string
  ##             : The filter to use to limit the number of results.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   filterValue: string
  ##              : The value to use for the filter.
  ##   status: string
  ##         : The phone number status.
  ##   productType: string
  ##              : The phone number product type.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603879 = newJObject()
  add(query_603879, "filter-name", newJString(filterName))
  add(query_603879, "NextToken", newJString(NextToken))
  add(query_603879, "max-results", newJInt(maxResults))
  add(query_603879, "filter-value", newJString(filterValue))
  add(query_603879, "status", newJString(status))
  add(query_603879, "product-type", newJString(productType))
  add(query_603879, "next-token", newJString(nextToken))
  add(query_603879, "MaxResults", newJString(MaxResults))
  result = call_603878.call(nil, query_603879, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_603859(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_603860, base: "/",
    url: url_ListPhoneNumbers_603861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_603880 = ref object of OpenApiRestCall_602466
proc url_ListVoiceConnectorTerminationCredentials_603882(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"),
               (kind: ConstantSegment, value: "/termination/credentials")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVoiceConnectorTerminationCredentials_603881(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603883 = path.getOrDefault("voiceConnectorId")
  valid_603883 = validateParameter(valid_603883, JString, required = true,
                                 default = nil)
  if valid_603883 != nil:
    section.add "voiceConnectorId", valid_603883
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603884 = header.getOrDefault("X-Amz-Date")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Date", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Security-Token")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Security-Token", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Content-Sha256", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Algorithm")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Algorithm", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Signature")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Signature", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-SignedHeaders", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Credential")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Credential", valid_603890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603891: Call_ListVoiceConnectorTerminationCredentials_603880;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603891.validator(path, query, header, formData, body)
  let scheme = call_603891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603891.url(scheme.get, call_603891.host, call_603891.base,
                         call_603891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603891, url, valid)

proc call*(call_603892: Call_ListVoiceConnectorTerminationCredentials_603880;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603893 = newJObject()
  add(path_603893, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603892.call(path_603893, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_603880(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_603881,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_603882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_603894 = ref object of OpenApiRestCall_602466
proc url_LogoutUser_603896(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "#operation=logout")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_LogoutUser_603895(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603897 = path.getOrDefault("accountId")
  valid_603897 = validateParameter(valid_603897, JString, required = true,
                                 default = nil)
  if valid_603897 != nil:
    section.add "accountId", valid_603897
  var valid_603898 = path.getOrDefault("userId")
  valid_603898 = validateParameter(valid_603898, JString, required = true,
                                 default = nil)
  if valid_603898 != nil:
    section.add "userId", valid_603898
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603899 = query.getOrDefault("operation")
  valid_603899 = validateParameter(valid_603899, JString, required = true,
                                 default = newJString("logout"))
  if valid_603899 != nil:
    section.add "operation", valid_603899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603900 = header.getOrDefault("X-Amz-Date")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Date", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Security-Token")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Security-Token", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Content-Sha256", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Algorithm")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Algorithm", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Signature")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Signature", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-SignedHeaders", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Credential")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Credential", valid_603906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603907: Call_LogoutUser_603894; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_603907.validator(path, query, header, formData, body)
  let scheme = call_603907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603907.url(scheme.get, call_603907.host, call_603907.base,
                         call_603907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603907, url, valid)

proc call*(call_603908: Call_LogoutUser_603894; accountId: string; userId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603909 = newJObject()
  var query_603910 = newJObject()
  add(path_603909, "accountId", newJString(accountId))
  add(query_603910, "operation", newJString(operation))
  add(path_603909, "userId", newJString(userId))
  result = call_603908.call(path_603909, query_603910, nil, nil, nil)

var logoutUser* = Call_LogoutUser_603894(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_603895,
                                      base: "/", url: url_LogoutUser_603896,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_603911 = ref object of OpenApiRestCall_602466
proc url_PutVoiceConnectorTerminationCredentials_603913(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId"), (
        kind: ConstantSegment, value: "/termination/credentials#operation=put")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutVoiceConnectorTerminationCredentials_603912(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_603914 = path.getOrDefault("voiceConnectorId")
  valid_603914 = validateParameter(valid_603914, JString, required = true,
                                 default = nil)
  if valid_603914 != nil:
    section.add "voiceConnectorId", valid_603914
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603915 = query.getOrDefault("operation")
  valid_603915 = validateParameter(valid_603915, JString, required = true,
                                 default = newJString("put"))
  if valid_603915 != nil:
    section.add "operation", valid_603915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603916 = header.getOrDefault("X-Amz-Date")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Date", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Security-Token")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Security-Token", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Content-Sha256", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Algorithm")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Algorithm", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Signature")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Signature", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-SignedHeaders", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Credential")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Credential", valid_603922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603924: Call_PutVoiceConnectorTerminationCredentials_603911;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603924.validator(path, query, header, formData, body)
  let scheme = call_603924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603924.url(scheme.get, call_603924.host, call_603924.base,
                         call_603924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603924, url, valid)

proc call*(call_603925: Call_PutVoiceConnectorTerminationCredentials_603911;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603926 = newJObject()
  var query_603927 = newJObject()
  var body_603928 = newJObject()
  add(path_603926, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603927, "operation", newJString(operation))
  if body != nil:
    body_603928 = body
  result = call_603925.call(path_603926, query_603927, nil, nil, body_603928)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_603911(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_603912, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_603913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_603929 = ref object of OpenApiRestCall_602466
proc url_RegenerateSecurityToken_603931(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "botId" in path, "`botId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botId"), (kind: ConstantSegment,
        value: "#operation=regenerate-security-token")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_RegenerateSecurityToken_603930(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Regenerates the security token for a bot.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   botId: JString (required)
  ##        : The bot ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603932 = path.getOrDefault("accountId")
  valid_603932 = validateParameter(valid_603932, JString, required = true,
                                 default = nil)
  if valid_603932 != nil:
    section.add "accountId", valid_603932
  var valid_603933 = path.getOrDefault("botId")
  valid_603933 = validateParameter(valid_603933, JString, required = true,
                                 default = nil)
  if valid_603933 != nil:
    section.add "botId", valid_603933
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603934 = query.getOrDefault("operation")
  valid_603934 = validateParameter(valid_603934, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_603934 != nil:
    section.add "operation", valid_603934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603935 = header.getOrDefault("X-Amz-Date")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Date", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Security-Token")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Security-Token", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Content-Sha256", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Algorithm")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Algorithm", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Signature")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Signature", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-SignedHeaders", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Credential")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Credential", valid_603941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603942: Call_RegenerateSecurityToken_603929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_603942.validator(path, query, header, formData, body)
  let scheme = call_603942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603942.url(scheme.get, call_603942.host, call_603942.base,
                         call_603942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603942, url, valid)

proc call*(call_603943: Call_RegenerateSecurityToken_603929; accountId: string;
          botId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  var path_603944 = newJObject()
  var query_603945 = newJObject()
  add(path_603944, "accountId", newJString(accountId))
  add(path_603944, "botId", newJString(botId))
  add(query_603945, "operation", newJString(operation))
  result = call_603943.call(path_603944, query_603945, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_603929(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_603930, base: "/",
    url: url_RegenerateSecurityToken_603931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_603946 = ref object of OpenApiRestCall_602466
proc url_ResetPersonalPIN_603948(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "userId"),
               (kind: ConstantSegment, value: "#operation=reset-personal-pin")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ResetPersonalPIN_603947(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   userId: JString (required)
  ##         : The user ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603949 = path.getOrDefault("accountId")
  valid_603949 = validateParameter(valid_603949, JString, required = true,
                                 default = nil)
  if valid_603949 != nil:
    section.add "accountId", valid_603949
  var valid_603950 = path.getOrDefault("userId")
  valid_603950 = validateParameter(valid_603950, JString, required = true,
                                 default = nil)
  if valid_603950 != nil:
    section.add "userId", valid_603950
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603951 = query.getOrDefault("operation")
  valid_603951 = validateParameter(valid_603951, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_603951 != nil:
    section.add "operation", valid_603951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603952 = header.getOrDefault("X-Amz-Date")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Date", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Security-Token")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Security-Token", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Content-Sha256", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Algorithm")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Algorithm", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Signature")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Signature", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-SignedHeaders", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Credential")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Credential", valid_603958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603959: Call_ResetPersonalPIN_603946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_603959.validator(path, query, header, formData, body)
  let scheme = call_603959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603959.url(scheme.get, call_603959.host, call_603959.base,
                         call_603959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603959, url, valid)

proc call*(call_603960: Call_ResetPersonalPIN_603946; accountId: string;
          userId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603961 = newJObject()
  var query_603962 = newJObject()
  add(path_603961, "accountId", newJString(accountId))
  add(query_603962, "operation", newJString(operation))
  add(path_603961, "userId", newJString(userId))
  result = call_603960.call(path_603961, query_603962, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_603946(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_603947, base: "/",
    url: url_ResetPersonalPIN_603948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_603963 = ref object of OpenApiRestCall_602466
proc url_RestorePhoneNumber_603965(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId"),
               (kind: ConstantSegment, value: "#operation=restore")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_RestorePhoneNumber_603964(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   phoneNumberId: JString (required)
  ##                : The phone number.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `phoneNumberId` field"
  var valid_603966 = path.getOrDefault("phoneNumberId")
  valid_603966 = validateParameter(valid_603966, JString, required = true,
                                 default = nil)
  if valid_603966 != nil:
    section.add "phoneNumberId", valid_603966
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603967 = query.getOrDefault("operation")
  valid_603967 = validateParameter(valid_603967, JString, required = true,
                                 default = newJString("restore"))
  if valid_603967 != nil:
    section.add "operation", valid_603967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603968 = header.getOrDefault("X-Amz-Date")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Date", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Security-Token")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Security-Token", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Content-Sha256", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Algorithm")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Algorithm", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Signature")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Signature", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-SignedHeaders", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Credential")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Credential", valid_603974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603975: Call_RestorePhoneNumber_603963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_603975.validator(path, query, header, formData, body)
  let scheme = call_603975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603975.url(scheme.get, call_603975.host, call_603975.base,
                         call_603975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603975, url, valid)

proc call*(call_603976: Call_RestorePhoneNumber_603963; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_603977 = newJObject()
  var query_603978 = newJObject()
  add(path_603977, "phoneNumberId", newJString(phoneNumberId))
  add(query_603978, "operation", newJString(operation))
  result = call_603976.call(path_603977, query_603978, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_603963(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_603964, base: "/",
    url: url_RestorePhoneNumber_603965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_603979 = ref object of OpenApiRestCall_602466
proc url_SearchAvailablePhoneNumbers_603981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchAvailablePhoneNumbers_603980(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches phone numbers that can be ordered.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   city: JString
  ##       : The city used to filter results.
  ##   toll-free-prefix: JString
  ##                   : The toll-free prefix that you use to filter results.
  ##   country: JString
  ##          : The country used to filter results.
  ##   area-code: JString
  ##            : The area code used to filter results.
  ##   type: JString (required)
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   state: JString
  ##        : The state used to filter results.
  section = newJObject()
  var valid_603982 = query.getOrDefault("city")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "city", valid_603982
  var valid_603983 = query.getOrDefault("toll-free-prefix")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "toll-free-prefix", valid_603983
  var valid_603984 = query.getOrDefault("country")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "country", valid_603984
  var valid_603985 = query.getOrDefault("area-code")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "area-code", valid_603985
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_603986 = query.getOrDefault("type")
  valid_603986 = validateParameter(valid_603986, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_603986 != nil:
    section.add "type", valid_603986
  var valid_603987 = query.getOrDefault("max-results")
  valid_603987 = validateParameter(valid_603987, JInt, required = false, default = nil)
  if valid_603987 != nil:
    section.add "max-results", valid_603987
  var valid_603988 = query.getOrDefault("next-token")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "next-token", valid_603988
  var valid_603989 = query.getOrDefault("state")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "state", valid_603989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603990 = header.getOrDefault("X-Amz-Date")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Date", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Security-Token")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Security-Token", valid_603991
  var valid_603992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Content-Sha256", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Algorithm")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Algorithm", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Signature")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Signature", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-SignedHeaders", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Credential")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Credential", valid_603996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603997: Call_SearchAvailablePhoneNumbers_603979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_603997.validator(path, query, header, formData, body)
  let scheme = call_603997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603997.url(scheme.get, call_603997.host, call_603997.base,
                         call_603997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603997, url, valid)

proc call*(call_603998: Call_SearchAvailablePhoneNumbers_603979; city: string = "";
          tollFreePrefix: string = ""; country: string = ""; areaCode: string = "";
          `type`: string = "phone-numbers"; maxResults: int = 0; nextToken: string = "";
          state: string = ""): Recallable =
  ## searchAvailablePhoneNumbers
  ## Searches phone numbers that can be ordered.
  ##   city: string
  ##       : The city used to filter results.
  ##   tollFreePrefix: string
  ##                 : The toll-free prefix that you use to filter results.
  ##   country: string
  ##          : The country used to filter results.
  ##   areaCode: string
  ##           : The area code used to filter results.
  ##   type: string (required)
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   state: string
  ##        : The state used to filter results.
  var query_603999 = newJObject()
  add(query_603999, "city", newJString(city))
  add(query_603999, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_603999, "country", newJString(country))
  add(query_603999, "area-code", newJString(areaCode))
  add(query_603999, "type", newJString(`type`))
  add(query_603999, "max-results", newJInt(maxResults))
  add(query_603999, "next-token", newJString(nextToken))
  add(query_603999, "state", newJString(state))
  result = call_603998.call(nil, query_603999, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_603979(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_603980, base: "/",
    url: url_SearchAvailablePhoneNumbers_603981,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
