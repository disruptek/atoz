
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Chime
## version: 2018-05-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The Amazon Chime API (application programming interface) is designed for developers to perform key tasks, such as creating and managing Amazon Chime accounts, users, and Voice Connectors. This guide provides detailed information about the Amazon Chime API, including operations, types, inputs and outputs, and error codes. It also includes some server-side API actions to use with the Amazon Chime SDK. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.</p> <p>You can use an AWS SDK, the AWS Command Line Interface (AWS CLI), or the REST API to make API calls. We recommend using an AWS SDK or the AWS CLI. Each API operation includes links to information about using it with a language-specific AWS SDK or the AWS CLI.</p> <dl> <dt>Using an AWS SDK</dt> <dd> <p>You don't need to write code to calculate a signature for request authentication. The SDK clients authenticate your requests by using access keys that you provide. For more information about AWS SDKs, see the <a href="http://aws.amazon.com/developer/">AWS Developer Center</a>.</p> </dd> <dt>Using the AWS CLI</dt> <dd> <p>Use your access keys with the AWS CLI to make API calls. For information about setting up the AWS CLI, see <a href="https://docs.aws.amazon.com/cli/latest/userguide/installing.html">Installing the AWS Command Line Interface</a> in the <i>AWS Command Line Interface User Guide</i>. For a list of available Amazon Chime commands, see the <a href="https://docs.aws.amazon.com/cli/latest/reference/chime/index.html">Amazon Chime commands</a> in the <i>AWS CLI Command Reference</i>.</p> </dd> <dt>Using REST API</dt> <dd> <p>If you use REST to make API calls, you must authenticate your request by providing a signature. Amazon Chime supports signature version 4. For more information, see <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>When making REST API calls, use the service name <code>chime</code> and REST endpoint <code>https://service.chime.aws.amazon.com</code>.</p> </dd> </dl> <p>Administrative permissions are controlled using AWS Identity and Access Management (IAM). For more information, see <a href="https://docs.aws.amazon.com/chime/latest/ag/security-iam.html">Identity and Access Management for Amazon Chime</a> in the <i>Amazon Chime Administration Guide</i>.</p>
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociatePhoneNumberWithUser_605927 = ref object of OpenApiRestCall_605589
proc url_AssociatePhoneNumberWithUser_605929(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociatePhoneNumberWithUser_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_606055 = path.getOrDefault("userId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "userId", valid_606055
  var valid_606056 = path.getOrDefault("accountId")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = nil)
  if valid_606056 != nil:
    section.add "accountId", valid_606056
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606070 = query.getOrDefault("operation")
  valid_606070 = validateParameter(valid_606070, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_606070 != nil:
    section.add "operation", valid_606070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606071 = header.getOrDefault("X-Amz-Signature")
  valid_606071 = validateParameter(valid_606071, JString, required = false,
                                 default = nil)
  if valid_606071 != nil:
    section.add "X-Amz-Signature", valid_606071
  var valid_606072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606072 = validateParameter(valid_606072, JString, required = false,
                                 default = nil)
  if valid_606072 != nil:
    section.add "X-Amz-Content-Sha256", valid_606072
  var valid_606073 = header.getOrDefault("X-Amz-Date")
  valid_606073 = validateParameter(valid_606073, JString, required = false,
                                 default = nil)
  if valid_606073 != nil:
    section.add "X-Amz-Date", valid_606073
  var valid_606074 = header.getOrDefault("X-Amz-Credential")
  valid_606074 = validateParameter(valid_606074, JString, required = false,
                                 default = nil)
  if valid_606074 != nil:
    section.add "X-Amz-Credential", valid_606074
  var valid_606075 = header.getOrDefault("X-Amz-Security-Token")
  valid_606075 = validateParameter(valid_606075, JString, required = false,
                                 default = nil)
  if valid_606075 != nil:
    section.add "X-Amz-Security-Token", valid_606075
  var valid_606076 = header.getOrDefault("X-Amz-Algorithm")
  valid_606076 = validateParameter(valid_606076, JString, required = false,
                                 default = nil)
  if valid_606076 != nil:
    section.add "X-Amz-Algorithm", valid_606076
  var valid_606077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606077 = validateParameter(valid_606077, JString, required = false,
                                 default = nil)
  if valid_606077 != nil:
    section.add "X-Amz-SignedHeaders", valid_606077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606101: Call_AssociatePhoneNumberWithUser_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_606101.validator(path, query, header, formData, body)
  let scheme = call_606101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606101.url(scheme.get, call_606101.host, call_606101.base,
                         call_606101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606101, url, valid)

proc call*(call_606172: Call_AssociatePhoneNumberWithUser_605927; userId: string;
          body: JsonNode; accountId: string;
          operation: string = "associate-phone-number"): Recallable =
  ## associatePhoneNumberWithUser
  ## Associates a phone number with the specified Amazon Chime user.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606173 = newJObject()
  var query_606175 = newJObject()
  var body_606176 = newJObject()
  add(query_606175, "operation", newJString(operation))
  add(path_606173, "userId", newJString(userId))
  if body != nil:
    body_606176 = body
  add(path_606173, "accountId", newJString(accountId))
  result = call_606172.call(path_606173, query_606175, nil, nil, body_606176)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_605927(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_605928, base: "/",
    url: url_AssociatePhoneNumberWithUser_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_606215 = ref object of OpenApiRestCall_605589
proc url_AssociatePhoneNumbersWithVoiceConnector_606217(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociatePhoneNumbersWithVoiceConnector_606216(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_606218 = path.getOrDefault("voiceConnectorId")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "voiceConnectorId", valid_606218
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606219 = query.getOrDefault("operation")
  valid_606219 = validateParameter(valid_606219, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_606219 != nil:
    section.add "operation", valid_606219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606220 = header.getOrDefault("X-Amz-Signature")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Signature", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Content-Sha256", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Date")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Date", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Credential")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Credential", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Security-Token")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Security-Token", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Algorithm")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Algorithm", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-SignedHeaders", valid_606226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606228: Call_AssociatePhoneNumbersWithVoiceConnector_606215;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_606228.validator(path, query, header, formData, body)
  let scheme = call_606228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606228.url(scheme.get, call_606228.host, call_606228.base,
                         call_606228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606228, url, valid)

proc call*(call_606229: Call_AssociatePhoneNumbersWithVoiceConnector_606215;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_606230 = newJObject()
  var query_606231 = newJObject()
  var body_606232 = newJObject()
  add(query_606231, "operation", newJString(operation))
  add(path_606230, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_606232 = body
  result = call_606229.call(path_606230, query_606231, nil, nil, body_606232)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_606215(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_606216, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_606217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnectorGroup_606233 = ref object of OpenApiRestCall_605589
proc url_AssociatePhoneNumbersWithVoiceConnectorGroup_606235(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorGroupId" in path,
        "`voiceConnectorGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connector-groups/"),
               (kind: VariableSegment, value: "voiceConnectorGroupId"), (
        kind: ConstantSegment, value: "#operation=associate-phone-numbers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociatePhoneNumbersWithVoiceConnectorGroup_606234(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_606236 = path.getOrDefault("voiceConnectorGroupId")
  valid_606236 = validateParameter(valid_606236, JString, required = true,
                                 default = nil)
  if valid_606236 != nil:
    section.add "voiceConnectorGroupId", valid_606236
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606237 = query.getOrDefault("operation")
  valid_606237 = validateParameter(valid_606237, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_606237 != nil:
    section.add "operation", valid_606237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606238 = header.getOrDefault("X-Amz-Signature")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Signature", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Content-Sha256", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Date")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Date", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Credential")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Credential", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Security-Token")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Security-Token", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Algorithm")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Algorithm", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-SignedHeaders", valid_606244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606246: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_606233;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_606246.validator(path, query, header, formData, body)
  let scheme = call_606246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606246.url(scheme.get, call_606246.host, call_606246.base,
                         call_606246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606246, url, valid)

proc call*(call_606247: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_606233;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnectorGroup
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_606248 = newJObject()
  var query_606249 = newJObject()
  var body_606250 = newJObject()
  add(path_606248, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_606249, "operation", newJString(operation))
  if body != nil:
    body_606250 = body
  result = call_606247.call(path_606248, query_606249, nil, nil, body_606250)

var associatePhoneNumbersWithVoiceConnectorGroup* = Call_AssociatePhoneNumbersWithVoiceConnectorGroup_606233(
    name: "associatePhoneNumbersWithVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnectorGroup_606234,
    base: "/", url: url_AssociatePhoneNumbersWithVoiceConnectorGroup_606235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSigninDelegateGroupsWithAccount_606251 = ref object of OpenApiRestCall_605589
proc url_AssociateSigninDelegateGroupsWithAccount_606253(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"), (kind: ConstantSegment,
        value: "#operation=associate-signin-delegate-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateSigninDelegateGroupsWithAccount_606252(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606254 = path.getOrDefault("accountId")
  valid_606254 = validateParameter(valid_606254, JString, required = true,
                                 default = nil)
  if valid_606254 != nil:
    section.add "accountId", valid_606254
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606255 = query.getOrDefault("operation")
  valid_606255 = validateParameter(valid_606255, JString, required = true, default = newJString(
      "associate-signin-delegate-groups"))
  if valid_606255 != nil:
    section.add "operation", valid_606255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606256 = header.getOrDefault("X-Amz-Signature")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Signature", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Content-Sha256", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Date")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Date", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Credential")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Credential", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Security-Token")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Security-Token", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Algorithm")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Algorithm", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-SignedHeaders", valid_606262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606264: Call_AssociateSigninDelegateGroupsWithAccount_606251;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ## 
  let valid = call_606264.validator(path, query, header, formData, body)
  let scheme = call_606264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606264.url(scheme.get, call_606264.host, call_606264.base,
                         call_606264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606264, url, valid)

proc call*(call_606265: Call_AssociateSigninDelegateGroupsWithAccount_606251;
          body: JsonNode; accountId: string;
          operation: string = "associate-signin-delegate-groups"): Recallable =
  ## associateSigninDelegateGroupsWithAccount
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606266 = newJObject()
  var query_606267 = newJObject()
  var body_606268 = newJObject()
  add(query_606267, "operation", newJString(operation))
  if body != nil:
    body_606268 = body
  add(path_606266, "accountId", newJString(accountId))
  result = call_606265.call(path_606266, query_606267, nil, nil, body_606268)

var associateSigninDelegateGroupsWithAccount* = Call_AssociateSigninDelegateGroupsWithAccount_606251(
    name: "associateSigninDelegateGroupsWithAccount", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}#operation=associate-signin-delegate-groups",
    validator: validate_AssociateSigninDelegateGroupsWithAccount_606252,
    base: "/", url: url_AssociateSigninDelegateGroupsWithAccount_606253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateAttendee_606269 = ref object of OpenApiRestCall_605589
proc url_BatchCreateAttendee_606271(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meetingId" in path, "`meetingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meetings/"),
               (kind: VariableSegment, value: "meetingId"), (kind: ConstantSegment,
        value: "/attendees#operation=batch-create")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchCreateAttendee_606270(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_606272 = path.getOrDefault("meetingId")
  valid_606272 = validateParameter(valid_606272, JString, required = true,
                                 default = nil)
  if valid_606272 != nil:
    section.add "meetingId", valid_606272
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606273 = query.getOrDefault("operation")
  valid_606273 = validateParameter(valid_606273, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_606273 != nil:
    section.add "operation", valid_606273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606274 = header.getOrDefault("X-Amz-Signature")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Signature", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Content-Sha256", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Date")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Date", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Credential")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Credential", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Security-Token")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Security-Token", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Algorithm")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Algorithm", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-SignedHeaders", valid_606280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606282: Call_BatchCreateAttendee_606269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  let valid = call_606282.validator(path, query, header, formData, body)
  let scheme = call_606282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606282.url(scheme.get, call_606282.host, call_606282.base,
                         call_606282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606282, url, valid)

proc call*(call_606283: Call_BatchCreateAttendee_606269; body: JsonNode;
          meetingId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateAttendee
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_606284 = newJObject()
  var query_606285 = newJObject()
  var body_606286 = newJObject()
  add(query_606285, "operation", newJString(operation))
  if body != nil:
    body_606286 = body
  add(path_606284, "meetingId", newJString(meetingId))
  result = call_606283.call(path_606284, query_606285, nil, nil, body_606286)

var batchCreateAttendee* = Call_BatchCreateAttendee_606269(
    name: "batchCreateAttendee", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees#operation=batch-create",
    validator: validate_BatchCreateAttendee_606270, base: "/",
    url: url_BatchCreateAttendee_606271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateRoomMembership_606287 = ref object of OpenApiRestCall_605589
proc url_BatchCreateRoomMembership_606289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId"), (kind: ConstantSegment,
        value: "/memberships#operation=batch-create")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchCreateRoomMembership_606288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606290 = path.getOrDefault("accountId")
  valid_606290 = validateParameter(valid_606290, JString, required = true,
                                 default = nil)
  if valid_606290 != nil:
    section.add "accountId", valid_606290
  var valid_606291 = path.getOrDefault("roomId")
  valid_606291 = validateParameter(valid_606291, JString, required = true,
                                 default = nil)
  if valid_606291 != nil:
    section.add "roomId", valid_606291
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606292 = query.getOrDefault("operation")
  valid_606292 = validateParameter(valid_606292, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_606292 != nil:
    section.add "operation", valid_606292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606293 = header.getOrDefault("X-Amz-Signature")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Signature", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Content-Sha256", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Date")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Date", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Credential")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Credential", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Security-Token")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Security-Token", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Algorithm")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Algorithm", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-SignedHeaders", valid_606299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606301: Call_BatchCreateRoomMembership_606287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_606301.validator(path, query, header, formData, body)
  let scheme = call_606301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606301.url(scheme.get, call_606301.host, call_606301.base,
                         call_606301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606301, url, valid)

proc call*(call_606302: Call_BatchCreateRoomMembership_606287; body: JsonNode;
          accountId: string; roomId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateRoomMembership
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_606303 = newJObject()
  var query_606304 = newJObject()
  var body_606305 = newJObject()
  add(query_606304, "operation", newJString(operation))
  if body != nil:
    body_606305 = body
  add(path_606303, "accountId", newJString(accountId))
  add(path_606303, "roomId", newJString(roomId))
  result = call_606302.call(path_606303, query_606304, nil, nil, body_606305)

var batchCreateRoomMembership* = Call_BatchCreateRoomMembership_606287(
    name: "batchCreateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}/memberships#operation=batch-create",
    validator: validate_BatchCreateRoomMembership_606288, base: "/",
    url: url_BatchCreateRoomMembership_606289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_606306 = ref object of OpenApiRestCall_605589
proc url_BatchDeletePhoneNumber_606308(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeletePhoneNumber_606307(path: JsonNode; query: JsonNode;
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
  var valid_606309 = query.getOrDefault("operation")
  valid_606309 = validateParameter(valid_606309, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_606309 != nil:
    section.add "operation", valid_606309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606310 = header.getOrDefault("X-Amz-Signature")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Signature", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Content-Sha256", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Date")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Date", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Credential")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Credential", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Security-Token")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Security-Token", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Algorithm")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Algorithm", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-SignedHeaders", valid_606316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606318: Call_BatchDeletePhoneNumber_606306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_606318.validator(path, query, header, formData, body)
  let scheme = call_606318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606318.url(scheme.get, call_606318.host, call_606318.base,
                         call_606318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606318, url, valid)

proc call*(call_606319: Call_BatchDeletePhoneNumber_606306; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_606320 = newJObject()
  var body_606321 = newJObject()
  add(query_606320, "operation", newJString(operation))
  if body != nil:
    body_606321 = body
  result = call_606319.call(nil, query_606320, nil, nil, body_606321)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_606306(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_606307, base: "/",
    url: url_BatchDeletePhoneNumber_606308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_606322 = ref object of OpenApiRestCall_605589
proc url_BatchSuspendUser_606324(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchSuspendUser_606323(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606325 = path.getOrDefault("accountId")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = nil)
  if valid_606325 != nil:
    section.add "accountId", valid_606325
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606326 = query.getOrDefault("operation")
  valid_606326 = validateParameter(valid_606326, JString, required = true,
                                 default = newJString("suspend"))
  if valid_606326 != nil:
    section.add "operation", valid_606326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606327 = header.getOrDefault("X-Amz-Signature")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Signature", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Content-Sha256", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Date")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Date", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Credential")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Credential", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Security-Token")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Security-Token", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Algorithm")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Algorithm", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-SignedHeaders", valid_606333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606335: Call_BatchSuspendUser_606322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_606335.validator(path, query, header, formData, body)
  let scheme = call_606335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606335.url(scheme.get, call_606335.host, call_606335.base,
                         call_606335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606335, url, valid)

proc call*(call_606336: Call_BatchSuspendUser_606322; body: JsonNode;
          accountId: string; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606337 = newJObject()
  var query_606338 = newJObject()
  var body_606339 = newJObject()
  add(query_606338, "operation", newJString(operation))
  if body != nil:
    body_606339 = body
  add(path_606337, "accountId", newJString(accountId))
  result = call_606336.call(path_606337, query_606338, nil, nil, body_606339)

var batchSuspendUser* = Call_BatchSuspendUser_606322(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_606323, base: "/",
    url: url_BatchSuspendUser_606324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_606340 = ref object of OpenApiRestCall_605589
proc url_BatchUnsuspendUser_606342(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchUnsuspendUser_606341(path: JsonNode; query: JsonNode;
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
  var valid_606343 = path.getOrDefault("accountId")
  valid_606343 = validateParameter(valid_606343, JString, required = true,
                                 default = nil)
  if valid_606343 != nil:
    section.add "accountId", valid_606343
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606344 = query.getOrDefault("operation")
  valid_606344 = validateParameter(valid_606344, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_606344 != nil:
    section.add "operation", valid_606344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606345 = header.getOrDefault("X-Amz-Signature")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Signature", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Content-Sha256", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Date")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Date", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Credential")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Credential", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Security-Token")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Security-Token", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Algorithm")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Algorithm", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-SignedHeaders", valid_606351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606353: Call_BatchUnsuspendUser_606340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_606353.validator(path, query, header, formData, body)
  let scheme = call_606353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606353.url(scheme.get, call_606353.host, call_606353.base,
                         call_606353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606353, url, valid)

proc call*(call_606354: Call_BatchUnsuspendUser_606340; body: JsonNode;
          accountId: string; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606355 = newJObject()
  var query_606356 = newJObject()
  var body_606357 = newJObject()
  add(query_606356, "operation", newJString(operation))
  if body != nil:
    body_606357 = body
  add(path_606355, "accountId", newJString(accountId))
  result = call_606354.call(path_606355, query_606356, nil, nil, body_606357)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_606340(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_606341, base: "/",
    url: url_BatchUnsuspendUser_606342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_606358 = ref object of OpenApiRestCall_605589
proc url_BatchUpdatePhoneNumber_606360(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchUpdatePhoneNumber_606359(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
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
  var valid_606361 = query.getOrDefault("operation")
  valid_606361 = validateParameter(valid_606361, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_606361 != nil:
    section.add "operation", valid_606361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606362 = header.getOrDefault("X-Amz-Signature")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Signature", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Content-Sha256", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Date")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Date", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Credential")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Credential", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Security-Token")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Security-Token", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Algorithm")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Algorithm", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-SignedHeaders", valid_606368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606370: Call_BatchUpdatePhoneNumber_606358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_606370.validator(path, query, header, formData, body)
  let scheme = call_606370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606370.url(scheme.get, call_606370.host, call_606370.base,
                         call_606370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606370, url, valid)

proc call*(call_606371: Call_BatchUpdatePhoneNumber_606358; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_606372 = newJObject()
  var body_606373 = newJObject()
  add(query_606372, "operation", newJString(operation))
  if body != nil:
    body_606373 = body
  result = call_606371.call(nil, query_606372, nil, nil, body_606373)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_606358(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_606359, base: "/",
    url: url_BatchUpdatePhoneNumber_606360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_606395 = ref object of OpenApiRestCall_605589
proc url_BatchUpdateUser_606397(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchUpdateUser_606396(path: JsonNode; query: JsonNode;
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
  var valid_606398 = path.getOrDefault("accountId")
  valid_606398 = validateParameter(valid_606398, JString, required = true,
                                 default = nil)
  if valid_606398 != nil:
    section.add "accountId", valid_606398
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606399 = header.getOrDefault("X-Amz-Signature")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Signature", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Content-Sha256", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Date")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Date", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Credential")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Credential", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Security-Token")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Security-Token", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Algorithm")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Algorithm", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-SignedHeaders", valid_606405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_BatchUpdateUser_606395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_BatchUpdateUser_606395; body: JsonNode;
          accountId: string): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606409 = newJObject()
  var body_606410 = newJObject()
  if body != nil:
    body_606410 = body
  add(path_606409, "accountId", newJString(accountId))
  result = call_606408.call(path_606409, nil, nil, nil, body_606410)

var batchUpdateUser* = Call_BatchUpdateUser_606395(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_606396,
    base: "/", url: url_BatchUpdateUser_606397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_606374 = ref object of OpenApiRestCall_605589
proc url_ListUsers_606376(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_606375(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606377 = path.getOrDefault("accountId")
  valid_606377 = validateParameter(valid_606377, JString, required = true,
                                 default = nil)
  if valid_606377 != nil:
    section.add "accountId", valid_606377
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   user-email: JString
  ##             : Optional. The user email address used to filter results. Maximum 1.
  ##   NextToken: JString
  ##            : Pagination token
  ##   user-type: JString
  ##            : The user type.
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Defaults to 100.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606378 = query.getOrDefault("MaxResults")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "MaxResults", valid_606378
  var valid_606379 = query.getOrDefault("user-email")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "user-email", valid_606379
  var valid_606380 = query.getOrDefault("NextToken")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "NextToken", valid_606380
  var valid_606381 = query.getOrDefault("user-type")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = newJString("PrivateUser"))
  if valid_606381 != nil:
    section.add "user-type", valid_606381
  var valid_606382 = query.getOrDefault("max-results")
  valid_606382 = validateParameter(valid_606382, JInt, required = false, default = nil)
  if valid_606382 != nil:
    section.add "max-results", valid_606382
  var valid_606383 = query.getOrDefault("next-token")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "next-token", valid_606383
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606384 = header.getOrDefault("X-Amz-Signature")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Signature", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Content-Sha256", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Date")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Date", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Credential")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Credential", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Security-Token")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Security-Token", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Algorithm")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Algorithm", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-SignedHeaders", valid_606390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606391: Call_ListUsers_606374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_606391.validator(path, query, header, formData, body)
  let scheme = call_606391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606391.url(scheme.get, call_606391.host, call_606391.base,
                         call_606391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606391, url, valid)

proc call*(call_606392: Call_ListUsers_606374; accountId: string;
          MaxResults: string = ""; userEmail: string = ""; NextToken: string = "";
          userType: string = "PrivateUser"; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   userEmail: string
  ##            : Optional. The user email address used to filter results. Maximum 1.
  ##   NextToken: string
  ##            : Pagination token
  ##   userType: string
  ##           : The user type.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Defaults to 100.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_606393 = newJObject()
  var query_606394 = newJObject()
  add(query_606394, "MaxResults", newJString(MaxResults))
  add(query_606394, "user-email", newJString(userEmail))
  add(query_606394, "NextToken", newJString(NextToken))
  add(query_606394, "user-type", newJString(userType))
  add(query_606394, "max-results", newJInt(maxResults))
  add(path_606393, "accountId", newJString(accountId))
  add(query_606394, "next-token", newJString(nextToken))
  result = call_606392.call(path_606393, query_606394, nil, nil, nil)

var listUsers* = Call_ListUsers_606374(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_606375,
                                    base: "/", url: url_ListUsers_606376,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_606430 = ref object of OpenApiRestCall_605589
proc url_CreateAccount_606432(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAccount_606431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606433 = header.getOrDefault("X-Amz-Signature")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Signature", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Content-Sha256", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Date")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Date", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Credential")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Credential", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Security-Token")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Security-Token", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Algorithm")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Algorithm", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-SignedHeaders", valid_606439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606441: Call_CreateAccount_606430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_606441.validator(path, query, header, formData, body)
  let scheme = call_606441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606441.url(scheme.get, call_606441.host, call_606441.base,
                         call_606441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606441, url, valid)

proc call*(call_606442: Call_CreateAccount_606430; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_606443 = newJObject()
  if body != nil:
    body_606443 = body
  result = call_606442.call(nil, nil, nil, nil, body_606443)

var createAccount* = Call_CreateAccount_606430(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_606431, base: "/", url: url_CreateAccount_606432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_606411 = ref object of OpenApiRestCall_605589
proc url_ListAccounts_606413(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_606412(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : Amazon Chime account name prefix with which to filter results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   user-email: JString
  ##             : User email address with which to filter results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Defaults to 100.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606414 = query.getOrDefault("name")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "name", valid_606414
  var valid_606415 = query.getOrDefault("MaxResults")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "MaxResults", valid_606415
  var valid_606416 = query.getOrDefault("user-email")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "user-email", valid_606416
  var valid_606417 = query.getOrDefault("NextToken")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "NextToken", valid_606417
  var valid_606418 = query.getOrDefault("max-results")
  valid_606418 = validateParameter(valid_606418, JInt, required = false, default = nil)
  if valid_606418 != nil:
    section.add "max-results", valid_606418
  var valid_606419 = query.getOrDefault("next-token")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "next-token", valid_606419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606420 = header.getOrDefault("X-Amz-Signature")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Signature", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Content-Sha256", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Date")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Date", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Credential")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Credential", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Security-Token")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Security-Token", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Algorithm")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Algorithm", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-SignedHeaders", valid_606426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606427: Call_ListAccounts_606411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_606427.validator(path, query, header, formData, body)
  let scheme = call_606427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606427.url(scheme.get, call_606427.host, call_606427.base,
                         call_606427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606427, url, valid)

proc call*(call_606428: Call_ListAccounts_606411; name: string = "";
          MaxResults: string = ""; userEmail: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listAccounts
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ##   name: string
  ##       : Amazon Chime account name prefix with which to filter results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   userEmail: string
  ##            : User email address with which to filter results.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Defaults to 100.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var query_606429 = newJObject()
  add(query_606429, "name", newJString(name))
  add(query_606429, "MaxResults", newJString(MaxResults))
  add(query_606429, "user-email", newJString(userEmail))
  add(query_606429, "NextToken", newJString(NextToken))
  add(query_606429, "max-results", newJInt(maxResults))
  add(query_606429, "next-token", newJString(nextToken))
  result = call_606428.call(nil, query_606429, nil, nil, nil)

var listAccounts* = Call_ListAccounts_606411(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_606412, base: "/", url: url_ListAccounts_606413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAttendee_606463 = ref object of OpenApiRestCall_605589
proc url_CreateAttendee_606465(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meetingId" in path, "`meetingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meetings/"),
               (kind: VariableSegment, value: "meetingId"),
               (kind: ConstantSegment, value: "/attendees")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAttendee_606464(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_606466 = path.getOrDefault("meetingId")
  valid_606466 = validateParameter(valid_606466, JString, required = true,
                                 default = nil)
  if valid_606466 != nil:
    section.add "meetingId", valid_606466
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606467 = header.getOrDefault("X-Amz-Signature")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Signature", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Content-Sha256", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Date")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Date", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Credential")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Credential", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Security-Token")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Security-Token", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Algorithm")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Algorithm", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-SignedHeaders", valid_606473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606475: Call_CreateAttendee_606463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606475.validator(path, query, header, formData, body)
  let scheme = call_606475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606475.url(scheme.get, call_606475.host, call_606475.base,
                         call_606475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606475, url, valid)

proc call*(call_606476: Call_CreateAttendee_606463; body: JsonNode; meetingId: string): Recallable =
  ## createAttendee
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_606477 = newJObject()
  var body_606478 = newJObject()
  if body != nil:
    body_606478 = body
  add(path_606477, "meetingId", newJString(meetingId))
  result = call_606476.call(path_606477, nil, nil, nil, body_606478)

var createAttendee* = Call_CreateAttendee_606463(name: "createAttendee",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_CreateAttendee_606464,
    base: "/", url: url_CreateAttendee_606465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttendees_606444 = ref object of OpenApiRestCall_605589
proc url_ListAttendees_606446(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meetingId" in path, "`meetingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meetings/"),
               (kind: VariableSegment, value: "meetingId"),
               (kind: ConstantSegment, value: "/attendees")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListAttendees_606445(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_606447 = path.getOrDefault("meetingId")
  valid_606447 = validateParameter(valid_606447, JString, required = true,
                                 default = nil)
  if valid_606447 != nil:
    section.add "meetingId", valid_606447
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606448 = query.getOrDefault("MaxResults")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "MaxResults", valid_606448
  var valid_606449 = query.getOrDefault("NextToken")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "NextToken", valid_606449
  var valid_606450 = query.getOrDefault("max-results")
  valid_606450 = validateParameter(valid_606450, JInt, required = false, default = nil)
  if valid_606450 != nil:
    section.add "max-results", valid_606450
  var valid_606451 = query.getOrDefault("next-token")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "next-token", valid_606451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606452 = header.getOrDefault("X-Amz-Signature")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Signature", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Content-Sha256", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Date")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Date", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Credential")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Credential", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Security-Token")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Security-Token", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Algorithm")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Algorithm", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-SignedHeaders", valid_606458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606459: Call_ListAttendees_606444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606459.validator(path, query, header, formData, body)
  let scheme = call_606459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606459.url(scheme.get, call_606459.host, call_606459.base,
                         call_606459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606459, url, valid)

proc call*(call_606460: Call_ListAttendees_606444; meetingId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listAttendees
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_606461 = newJObject()
  var query_606462 = newJObject()
  add(query_606462, "MaxResults", newJString(MaxResults))
  add(query_606462, "NextToken", newJString(NextToken))
  add(query_606462, "max-results", newJInt(maxResults))
  add(path_606461, "meetingId", newJString(meetingId))
  add(query_606462, "next-token", newJString(nextToken))
  result = call_606460.call(path_606461, query_606462, nil, nil, nil)

var listAttendees* = Call_ListAttendees_606444(name: "listAttendees",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_ListAttendees_606445,
    base: "/", url: url_ListAttendees_606446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_606498 = ref object of OpenApiRestCall_605589
proc url_CreateBot_606500(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBot_606499(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606501 = path.getOrDefault("accountId")
  valid_606501 = validateParameter(valid_606501, JString, required = true,
                                 default = nil)
  if valid_606501 != nil:
    section.add "accountId", valid_606501
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606502 = header.getOrDefault("X-Amz-Signature")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Signature", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Content-Sha256", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Date")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Date", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Credential")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Credential", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Security-Token")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Security-Token", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Algorithm")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Algorithm", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-SignedHeaders", valid_606508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606510: Call_CreateBot_606498; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_606510.validator(path, query, header, formData, body)
  let scheme = call_606510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606510.url(scheme.get, call_606510.host, call_606510.base,
                         call_606510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606510, url, valid)

proc call*(call_606511: Call_CreateBot_606498; body: JsonNode; accountId: string): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606512 = newJObject()
  var body_606513 = newJObject()
  if body != nil:
    body_606513 = body
  add(path_606512, "accountId", newJString(accountId))
  result = call_606511.call(path_606512, nil, nil, nil, body_606513)

var createBot* = Call_CreateBot_606498(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_606499,
                                    base: "/", url: url_CreateBot_606500,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_606479 = ref object of OpenApiRestCall_605589
proc url_ListBots_606481(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBots_606480(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606482 = path.getOrDefault("accountId")
  valid_606482 = validateParameter(valid_606482, JString, required = true,
                                 default = nil)
  if valid_606482 != nil:
    section.add "accountId", valid_606482
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. The default is 10.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606483 = query.getOrDefault("MaxResults")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "MaxResults", valid_606483
  var valid_606484 = query.getOrDefault("NextToken")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "NextToken", valid_606484
  var valid_606485 = query.getOrDefault("max-results")
  valid_606485 = validateParameter(valid_606485, JInt, required = false, default = nil)
  if valid_606485 != nil:
    section.add "max-results", valid_606485
  var valid_606486 = query.getOrDefault("next-token")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "next-token", valid_606486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606487 = header.getOrDefault("X-Amz-Signature")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Signature", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Content-Sha256", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Date")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Date", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Credential")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Credential", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Security-Token")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Security-Token", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Algorithm")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Algorithm", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-SignedHeaders", valid_606493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606494: Call_ListBots_606479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_606494.validator(path, query, header, formData, body)
  let scheme = call_606494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606494.url(scheme.get, call_606494.host, call_606494.base,
                         call_606494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606494, url, valid)

proc call*(call_606495: Call_ListBots_606479; accountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBots
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. The default is 10.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_606496 = newJObject()
  var query_606497 = newJObject()
  add(query_606497, "MaxResults", newJString(MaxResults))
  add(query_606497, "NextToken", newJString(NextToken))
  add(query_606497, "max-results", newJInt(maxResults))
  add(path_606496, "accountId", newJString(accountId))
  add(query_606497, "next-token", newJString(nextToken))
  result = call_606495.call(path_606496, query_606497, nil, nil, nil)

var listBots* = Call_ListBots_606479(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_606480, base: "/",
                                  url: url_ListBots_606481,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMeeting_606531 = ref object of OpenApiRestCall_605589
proc url_CreateMeeting_606533(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMeeting_606532(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606534 = header.getOrDefault("X-Amz-Signature")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Signature", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Content-Sha256", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Date")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Date", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Credential")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Credential", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Security-Token")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Security-Token", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Algorithm")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Algorithm", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-SignedHeaders", valid_606540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606542: Call_CreateMeeting_606531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606542.validator(path, query, header, formData, body)
  let scheme = call_606542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606542.url(scheme.get, call_606542.host, call_606542.base,
                         call_606542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606542, url, valid)

proc call*(call_606543: Call_CreateMeeting_606531; body: JsonNode): Recallable =
  ## createMeeting
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  var body_606544 = newJObject()
  if body != nil:
    body_606544 = body
  result = call_606543.call(nil, nil, nil, nil, body_606544)

var createMeeting* = Call_CreateMeeting_606531(name: "createMeeting",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_CreateMeeting_606532, base: "/", url: url_CreateMeeting_606533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeetings_606514 = ref object of OpenApiRestCall_605589
proc url_ListMeetings_606516(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeetings_606515(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606517 = query.getOrDefault("MaxResults")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "MaxResults", valid_606517
  var valid_606518 = query.getOrDefault("NextToken")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "NextToken", valid_606518
  var valid_606519 = query.getOrDefault("max-results")
  valid_606519 = validateParameter(valid_606519, JInt, required = false, default = nil)
  if valid_606519 != nil:
    section.add "max-results", valid_606519
  var valid_606520 = query.getOrDefault("next-token")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "next-token", valid_606520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606521 = header.getOrDefault("X-Amz-Signature")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Signature", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Content-Sha256", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Date")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Date", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Credential")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Credential", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Security-Token")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Security-Token", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Algorithm")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Algorithm", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-SignedHeaders", valid_606527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606528: Call_ListMeetings_606514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606528.validator(path, query, header, formData, body)
  let scheme = call_606528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606528.url(scheme.get, call_606528.host, call_606528.base,
                         call_606528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606528, url, valid)

proc call*(call_606529: Call_ListMeetings_606514; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listMeetings
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var query_606530 = newJObject()
  add(query_606530, "MaxResults", newJString(MaxResults))
  add(query_606530, "NextToken", newJString(NextToken))
  add(query_606530, "max-results", newJInt(maxResults))
  add(query_606530, "next-token", newJString(nextToken))
  result = call_606529.call(nil, query_606530, nil, nil, nil)

var listMeetings* = Call_ListMeetings_606514(name: "listMeetings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_ListMeetings_606515, base: "/", url: url_ListMeetings_606516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_606562 = ref object of OpenApiRestCall_605589
proc url_CreatePhoneNumberOrder_606564(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePhoneNumberOrder_606563(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606565 = header.getOrDefault("X-Amz-Signature")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Signature", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Content-Sha256", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Date")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Date", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Credential")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Credential", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Security-Token")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Security-Token", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Algorithm")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Algorithm", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-SignedHeaders", valid_606571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606573: Call_CreatePhoneNumberOrder_606562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_606573.validator(path, query, header, formData, body)
  let scheme = call_606573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606573.url(scheme.get, call_606573.host, call_606573.base,
                         call_606573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606573, url, valid)

proc call*(call_606574: Call_CreatePhoneNumberOrder_606562; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_606575 = newJObject()
  if body != nil:
    body_606575 = body
  result = call_606574.call(nil, nil, nil, nil, body_606575)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_606562(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_606563, base: "/",
    url: url_CreatePhoneNumberOrder_606564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_606545 = ref object of OpenApiRestCall_605589
proc url_ListPhoneNumberOrders_606547(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumberOrders_606546(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606548 = query.getOrDefault("MaxResults")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "MaxResults", valid_606548
  var valid_606549 = query.getOrDefault("NextToken")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "NextToken", valid_606549
  var valid_606550 = query.getOrDefault("max-results")
  valid_606550 = validateParameter(valid_606550, JInt, required = false, default = nil)
  if valid_606550 != nil:
    section.add "max-results", valid_606550
  var valid_606551 = query.getOrDefault("next-token")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "next-token", valid_606551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606552 = header.getOrDefault("X-Amz-Signature")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Signature", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Content-Sha256", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Date")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Date", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Credential")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Credential", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Security-Token")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Security-Token", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Algorithm")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Algorithm", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-SignedHeaders", valid_606558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606559: Call_ListPhoneNumberOrders_606545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_606559.validator(path, query, header, formData, body)
  let scheme = call_606559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606559.url(scheme.get, call_606559.host, call_606559.base,
                         call_606559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606559, url, valid)

proc call*(call_606560: Call_ListPhoneNumberOrders_606545; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listPhoneNumberOrders
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var query_606561 = newJObject()
  add(query_606561, "MaxResults", newJString(MaxResults))
  add(query_606561, "NextToken", newJString(NextToken))
  add(query_606561, "max-results", newJInt(maxResults))
  add(query_606561, "next-token", newJString(nextToken))
  result = call_606560.call(nil, query_606561, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_606545(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_606546, base: "/",
    url: url_ListPhoneNumberOrders_606547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_606596 = ref object of OpenApiRestCall_605589
proc url_CreateRoom_606598(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoom_606597(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a chat room for the specified Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606599 = path.getOrDefault("accountId")
  valid_606599 = validateParameter(valid_606599, JString, required = true,
                                 default = nil)
  if valid_606599 != nil:
    section.add "accountId", valid_606599
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606600 = header.getOrDefault("X-Amz-Signature")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Signature", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Content-Sha256", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Date")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Date", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Credential")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Credential", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Security-Token")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Security-Token", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Algorithm")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Algorithm", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-SignedHeaders", valid_606606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606608: Call_CreateRoom_606596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a chat room for the specified Amazon Chime account.
  ## 
  let valid = call_606608.validator(path, query, header, formData, body)
  let scheme = call_606608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606608.url(scheme.get, call_606608.host, call_606608.base,
                         call_606608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606608, url, valid)

proc call*(call_606609: Call_CreateRoom_606596; body: JsonNode; accountId: string): Recallable =
  ## createRoom
  ## Creates a chat room for the specified Amazon Chime account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606610 = newJObject()
  var body_606611 = newJObject()
  if body != nil:
    body_606611 = body
  add(path_606610, "accountId", newJString(accountId))
  result = call_606609.call(path_606610, nil, nil, nil, body_606611)

var createRoom* = Call_CreateRoom_606596(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/rooms",
                                      validator: validate_CreateRoom_606597,
                                      base: "/", url: url_CreateRoom_606598,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRooms_606576 = ref object of OpenApiRestCall_605589
proc url_ListRooms_606578(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRooms_606577(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the room details for the specified Amazon Chime account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606579 = path.getOrDefault("accountId")
  valid_606579 = validateParameter(valid_606579, JString, required = true,
                                 default = nil)
  if valid_606579 != nil:
    section.add "accountId", valid_606579
  result.add "path", section
  ## parameters in `query` object:
  ##   member-id: JString
  ##            : The member ID (user ID or bot ID).
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606580 = query.getOrDefault("member-id")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "member-id", valid_606580
  var valid_606581 = query.getOrDefault("MaxResults")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "MaxResults", valid_606581
  var valid_606582 = query.getOrDefault("NextToken")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "NextToken", valid_606582
  var valid_606583 = query.getOrDefault("max-results")
  valid_606583 = validateParameter(valid_606583, JInt, required = false, default = nil)
  if valid_606583 != nil:
    section.add "max-results", valid_606583
  var valid_606584 = query.getOrDefault("next-token")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "next-token", valid_606584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606585 = header.getOrDefault("X-Amz-Signature")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Signature", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Content-Sha256", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Date")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Date", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Credential")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Credential", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Security-Token")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Security-Token", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Algorithm")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Algorithm", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-SignedHeaders", valid_606591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606592: Call_ListRooms_606576; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the room details for the specified Amazon Chime account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  let valid = call_606592.validator(path, query, header, formData, body)
  let scheme = call_606592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606592.url(scheme.get, call_606592.host, call_606592.base,
                         call_606592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606592, url, valid)

proc call*(call_606593: Call_ListRooms_606576; accountId: string;
          memberId: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listRooms
  ## Lists the room details for the specified Amazon Chime account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ##   memberId: string
  ##           : The member ID (user ID or bot ID).
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_606594 = newJObject()
  var query_606595 = newJObject()
  add(query_606595, "member-id", newJString(memberId))
  add(query_606595, "MaxResults", newJString(MaxResults))
  add(query_606595, "NextToken", newJString(NextToken))
  add(query_606595, "max-results", newJInt(maxResults))
  add(path_606594, "accountId", newJString(accountId))
  add(query_606595, "next-token", newJString(nextToken))
  result = call_606593.call(path_606594, query_606595, nil, nil, nil)

var listRooms* = Call_ListRooms_606576(name: "listRooms", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/rooms",
                                    validator: validate_ListRooms_606577,
                                    base: "/", url: url_ListRooms_606578,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoomMembership_606632 = ref object of OpenApiRestCall_605589
proc url_CreateRoomMembership_606634(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId"),
               (kind: ConstantSegment, value: "/memberships")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoomMembership_606633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606635 = path.getOrDefault("accountId")
  valid_606635 = validateParameter(valid_606635, JString, required = true,
                                 default = nil)
  if valid_606635 != nil:
    section.add "accountId", valid_606635
  var valid_606636 = path.getOrDefault("roomId")
  valid_606636 = validateParameter(valid_606636, JString, required = true,
                                 default = nil)
  if valid_606636 != nil:
    section.add "roomId", valid_606636
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606637 = header.getOrDefault("X-Amz-Signature")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Signature", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Content-Sha256", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Date")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Date", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Credential")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Credential", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Security-Token")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Security-Token", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Algorithm")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Algorithm", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-SignedHeaders", valid_606643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606645: Call_CreateRoomMembership_606632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_606645.validator(path, query, header, formData, body)
  let scheme = call_606645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606645.url(scheme.get, call_606645.host, call_606645.base,
                         call_606645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606645, url, valid)

proc call*(call_606646: Call_CreateRoomMembership_606632; body: JsonNode;
          accountId: string; roomId: string): Recallable =
  ## createRoomMembership
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_606647 = newJObject()
  var body_606648 = newJObject()
  if body != nil:
    body_606648 = body
  add(path_606647, "accountId", newJString(accountId))
  add(path_606647, "roomId", newJString(roomId))
  result = call_606646.call(path_606647, nil, nil, nil, body_606648)

var createRoomMembership* = Call_CreateRoomMembership_606632(
    name: "createRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_CreateRoomMembership_606633, base: "/",
    url: url_CreateRoomMembership_606634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoomMemberships_606612 = ref object of OpenApiRestCall_605589
proc url_ListRoomMemberships_606614(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId"),
               (kind: ConstantSegment, value: "/memberships")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRoomMemberships_606613(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the membership details for the specified room, such as the members' IDs, email addresses, and names.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606615 = path.getOrDefault("accountId")
  valid_606615 = validateParameter(valid_606615, JString, required = true,
                                 default = nil)
  if valid_606615 != nil:
    section.add "accountId", valid_606615
  var valid_606616 = path.getOrDefault("roomId")
  valid_606616 = validateParameter(valid_606616, JString, required = true,
                                 default = nil)
  if valid_606616 != nil:
    section.add "roomId", valid_606616
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606617 = query.getOrDefault("MaxResults")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "MaxResults", valid_606617
  var valid_606618 = query.getOrDefault("NextToken")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "NextToken", valid_606618
  var valid_606619 = query.getOrDefault("max-results")
  valid_606619 = validateParameter(valid_606619, JInt, required = false, default = nil)
  if valid_606619 != nil:
    section.add "max-results", valid_606619
  var valid_606620 = query.getOrDefault("next-token")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "next-token", valid_606620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606621 = header.getOrDefault("X-Amz-Signature")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Signature", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Content-Sha256", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Date")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Date", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Credential")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Credential", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Security-Token")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Security-Token", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Algorithm")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Algorithm", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-SignedHeaders", valid_606627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606628: Call_ListRoomMemberships_606612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the membership details for the specified room, such as the members' IDs, email addresses, and names.
  ## 
  let valid = call_606628.validator(path, query, header, formData, body)
  let scheme = call_606628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606628.url(scheme.get, call_606628.host, call_606628.base,
                         call_606628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606628, url, valid)

proc call*(call_606629: Call_ListRoomMemberships_606612; accountId: string;
          roomId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listRoomMemberships
  ## Lists the membership details for the specified room, such as the members' IDs, email addresses, and names.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_606630 = newJObject()
  var query_606631 = newJObject()
  add(query_606631, "MaxResults", newJString(MaxResults))
  add(query_606631, "NextToken", newJString(NextToken))
  add(query_606631, "max-results", newJInt(maxResults))
  add(path_606630, "accountId", newJString(accountId))
  add(path_606630, "roomId", newJString(roomId))
  add(query_606631, "next-token", newJString(nextToken))
  result = call_606629.call(path_606630, query_606631, nil, nil, nil)

var listRoomMemberships* = Call_ListRoomMemberships_606612(
    name: "listRoomMemberships", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_ListRoomMemberships_606613, base: "/",
    url: url_ListRoomMemberships_606614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_606649 = ref object of OpenApiRestCall_605589
proc url_CreateUser_606651(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users#operation=create")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUser_606650(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a user under the specified Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606652 = path.getOrDefault("accountId")
  valid_606652 = validateParameter(valid_606652, JString, required = true,
                                 default = nil)
  if valid_606652 != nil:
    section.add "accountId", valid_606652
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_606653 = query.getOrDefault("operation")
  valid_606653 = validateParameter(valid_606653, JString, required = true,
                                 default = newJString("create"))
  if valid_606653 != nil:
    section.add "operation", valid_606653
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606654 = header.getOrDefault("X-Amz-Signature")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Signature", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Content-Sha256", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Date")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Date", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Credential")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Credential", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Security-Token")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Security-Token", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Algorithm")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Algorithm", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-SignedHeaders", valid_606660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606662: Call_CreateUser_606649; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user under the specified Amazon Chime account.
  ## 
  let valid = call_606662.validator(path, query, header, formData, body)
  let scheme = call_606662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606662.url(scheme.get, call_606662.host, call_606662.base,
                         call_606662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606662, url, valid)

proc call*(call_606663: Call_CreateUser_606649; body: JsonNode; accountId: string;
          operation: string = "create"): Recallable =
  ## createUser
  ## Creates a user under the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606664 = newJObject()
  var query_606665 = newJObject()
  var body_606666 = newJObject()
  add(query_606665, "operation", newJString(operation))
  if body != nil:
    body_606666 = body
  add(path_606664, "accountId", newJString(accountId))
  result = call_606663.call(path_606664, query_606665, nil, nil, body_606666)

var createUser* = Call_CreateUser_606649(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=create",
                                      validator: validate_CreateUser_606650,
                                      base: "/", url: url_CreateUser_606651,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_606684 = ref object of OpenApiRestCall_605589
proc url_CreateVoiceConnector_606686(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnector_606685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606687 = header.getOrDefault("X-Amz-Signature")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Signature", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Content-Sha256", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Date")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Date", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Credential")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Credential", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Security-Token")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Security-Token", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Algorithm")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Algorithm", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-SignedHeaders", valid_606693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606695: Call_CreateVoiceConnector_606684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  let valid = call_606695.validator(path, query, header, formData, body)
  let scheme = call_606695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606695.url(scheme.get, call_606695.host, call_606695.base,
                         call_606695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606695, url, valid)

proc call*(call_606696: Call_CreateVoiceConnector_606684; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ##   body: JObject (required)
  var body_606697 = newJObject()
  if body != nil:
    body_606697 = body
  result = call_606696.call(nil, nil, nil, nil, body_606697)

var createVoiceConnector* = Call_CreateVoiceConnector_606684(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_606685, base: "/",
    url: url_CreateVoiceConnector_606686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_606667 = ref object of OpenApiRestCall_605589
proc url_ListVoiceConnectors_606669(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectors_606668(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606670 = query.getOrDefault("MaxResults")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "MaxResults", valid_606670
  var valid_606671 = query.getOrDefault("NextToken")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "NextToken", valid_606671
  var valid_606672 = query.getOrDefault("max-results")
  valid_606672 = validateParameter(valid_606672, JInt, required = false, default = nil)
  if valid_606672 != nil:
    section.add "max-results", valid_606672
  var valid_606673 = query.getOrDefault("next-token")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "next-token", valid_606673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606674 = header.getOrDefault("X-Amz-Signature")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Signature", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Content-Sha256", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Date")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Date", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Credential")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Credential", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Security-Token")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Security-Token", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Algorithm")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Algorithm", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-SignedHeaders", valid_606680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606681: Call_ListVoiceConnectors_606667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_606681.validator(path, query, header, formData, body)
  let scheme = call_606681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606681.url(scheme.get, call_606681.host, call_606681.base,
                         call_606681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606681, url, valid)

proc call*(call_606682: Call_ListVoiceConnectors_606667; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listVoiceConnectors
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var query_606683 = newJObject()
  add(query_606683, "MaxResults", newJString(MaxResults))
  add(query_606683, "NextToken", newJString(NextToken))
  add(query_606683, "max-results", newJInt(maxResults))
  add(query_606683, "next-token", newJString(nextToken))
  result = call_606682.call(nil, query_606683, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_606667(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_606668, base: "/",
    url: url_ListVoiceConnectors_606669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnectorGroup_606715 = ref object of OpenApiRestCall_605589
proc url_CreateVoiceConnectorGroup_606717(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnectorGroup_606716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606718 = header.getOrDefault("X-Amz-Signature")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Signature", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Content-Sha256", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Date")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Date", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Credential")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Credential", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Security-Token")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Security-Token", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Algorithm")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Algorithm", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-SignedHeaders", valid_606724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606726: Call_CreateVoiceConnectorGroup_606715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  let valid = call_606726.validator(path, query, header, formData, body)
  let scheme = call_606726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606726.url(scheme.get, call_606726.host, call_606726.base,
                         call_606726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606726, url, valid)

proc call*(call_606727: Call_CreateVoiceConnectorGroup_606715; body: JsonNode): Recallable =
  ## createVoiceConnectorGroup
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ##   body: JObject (required)
  var body_606728 = newJObject()
  if body != nil:
    body_606728 = body
  result = call_606727.call(nil, nil, nil, nil, body_606728)

var createVoiceConnectorGroup* = Call_CreateVoiceConnectorGroup_606715(
    name: "createVoiceConnectorGroup", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_CreateVoiceConnectorGroup_606716, base: "/",
    url: url_CreateVoiceConnectorGroup_606717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorGroups_606698 = ref object of OpenApiRestCall_605589
proc url_ListVoiceConnectorGroups_606700(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectorGroups_606699(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_606701 = query.getOrDefault("MaxResults")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "MaxResults", valid_606701
  var valid_606702 = query.getOrDefault("NextToken")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "NextToken", valid_606702
  var valid_606703 = query.getOrDefault("max-results")
  valid_606703 = validateParameter(valid_606703, JInt, required = false, default = nil)
  if valid_606703 != nil:
    section.add "max-results", valid_606703
  var valid_606704 = query.getOrDefault("next-token")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "next-token", valid_606704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606705 = header.getOrDefault("X-Amz-Signature")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Signature", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Content-Sha256", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Date")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Date", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Credential")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Credential", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Security-Token")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Security-Token", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Algorithm")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Algorithm", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-SignedHeaders", valid_606711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606712: Call_ListVoiceConnectorGroups_606698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  let valid = call_606712.validator(path, query, header, formData, body)
  let scheme = call_606712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606712.url(scheme.get, call_606712.host, call_606712.base,
                         call_606712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606712, url, valid)

proc call*(call_606713: Call_ListVoiceConnectorGroups_606698;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listVoiceConnectorGroups
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var query_606714 = newJObject()
  add(query_606714, "MaxResults", newJString(MaxResults))
  add(query_606714, "NextToken", newJString(NextToken))
  add(query_606714, "max-results", newJInt(maxResults))
  add(query_606714, "next-token", newJString(nextToken))
  result = call_606713.call(nil, query_606714, nil, nil, nil)

var listVoiceConnectorGroups* = Call_ListVoiceConnectorGroups_606698(
    name: "listVoiceConnectorGroups", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_ListVoiceConnectorGroups_606699, base: "/",
    url: url_ListVoiceConnectorGroups_606700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_606743 = ref object of OpenApiRestCall_605589
proc url_UpdateAccount_606745(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAccount_606744(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606746 = path.getOrDefault("accountId")
  valid_606746 = validateParameter(valid_606746, JString, required = true,
                                 default = nil)
  if valid_606746 != nil:
    section.add "accountId", valid_606746
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606747 = header.getOrDefault("X-Amz-Signature")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Signature", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Content-Sha256", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Date")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Date", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Credential")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Credential", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Security-Token")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Security-Token", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Algorithm")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Algorithm", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-SignedHeaders", valid_606753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606755: Call_UpdateAccount_606743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_606755.validator(path, query, header, formData, body)
  let scheme = call_606755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606755.url(scheme.get, call_606755.host, call_606755.base,
                         call_606755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606755, url, valid)

proc call*(call_606756: Call_UpdateAccount_606743; body: JsonNode; accountId: string): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606757 = newJObject()
  var body_606758 = newJObject()
  if body != nil:
    body_606758 = body
  add(path_606757, "accountId", newJString(accountId))
  result = call_606756.call(path_606757, nil, nil, nil, body_606758)

var updateAccount* = Call_UpdateAccount_606743(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_606744,
    base: "/", url: url_UpdateAccount_606745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_606729 = ref object of OpenApiRestCall_605589
proc url_GetAccount_606731(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccount_606730(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606732 = path.getOrDefault("accountId")
  valid_606732 = validateParameter(valid_606732, JString, required = true,
                                 default = nil)
  if valid_606732 != nil:
    section.add "accountId", valid_606732
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606733 = header.getOrDefault("X-Amz-Signature")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Signature", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Content-Sha256", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Date")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Date", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Credential")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Credential", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Security-Token")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Security-Token", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Algorithm")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Algorithm", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-SignedHeaders", valid_606739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606740: Call_GetAccount_606729; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_606740.validator(path, query, header, formData, body)
  let scheme = call_606740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606740.url(scheme.get, call_606740.host, call_606740.base,
                         call_606740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606740, url, valid)

proc call*(call_606741: Call_GetAccount_606729; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606742 = newJObject()
  add(path_606742, "accountId", newJString(accountId))
  result = call_606741.call(path_606742, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_606729(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_606730,
                                      base: "/", url: url_GetAccount_606731,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_606759 = ref object of OpenApiRestCall_605589
proc url_DeleteAccount_606761(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccount_606760(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606762 = path.getOrDefault("accountId")
  valid_606762 = validateParameter(valid_606762, JString, required = true,
                                 default = nil)
  if valid_606762 != nil:
    section.add "accountId", valid_606762
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606763 = header.getOrDefault("X-Amz-Signature")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Signature", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Content-Sha256", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Date")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Date", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Credential")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Credential", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Security-Token")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Security-Token", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Algorithm")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Algorithm", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-SignedHeaders", valid_606769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606770: Call_DeleteAccount_606759; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_606770.validator(path, query, header, formData, body)
  let scheme = call_606770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606770.url(scheme.get, call_606770.host, call_606770.base,
                         call_606770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606770, url, valid)

proc call*(call_606771: Call_DeleteAccount_606759; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606772 = newJObject()
  add(path_606772, "accountId", newJString(accountId))
  result = call_606771.call(path_606772, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_606759(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_606760,
    base: "/", url: url_DeleteAccount_606761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttendee_606773 = ref object of OpenApiRestCall_605589
proc url_GetAttendee_606775(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meetingId" in path, "`meetingId` is a required path parameter"
  assert "attendeeId" in path, "`attendeeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meetings/"),
               (kind: VariableSegment, value: "meetingId"),
               (kind: ConstantSegment, value: "/attendees/"),
               (kind: VariableSegment, value: "attendeeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAttendee_606774(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   attendeeId: JString (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `attendeeId` field"
  var valid_606776 = path.getOrDefault("attendeeId")
  valid_606776 = validateParameter(valid_606776, JString, required = true,
                                 default = nil)
  if valid_606776 != nil:
    section.add "attendeeId", valid_606776
  var valid_606777 = path.getOrDefault("meetingId")
  valid_606777 = validateParameter(valid_606777, JString, required = true,
                                 default = nil)
  if valid_606777 != nil:
    section.add "meetingId", valid_606777
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606778 = header.getOrDefault("X-Amz-Signature")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Signature", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Content-Sha256", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Date")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Date", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Credential")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Credential", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Security-Token")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Security-Token", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Algorithm")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Algorithm", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-SignedHeaders", valid_606784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_GetAttendee_606773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_GetAttendee_606773; attendeeId: string;
          meetingId: string): Recallable =
  ## getAttendee
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_606787 = newJObject()
  add(path_606787, "attendeeId", newJString(attendeeId))
  add(path_606787, "meetingId", newJString(meetingId))
  result = call_606786.call(path_606787, nil, nil, nil, nil)

var getAttendee* = Call_GetAttendee_606773(name: "getAttendee",
                                        meth: HttpMethod.HttpGet,
                                        host: "chime.amazonaws.com", route: "/meetings/{meetingId}/attendees/{attendeeId}",
                                        validator: validate_GetAttendee_606774,
                                        base: "/", url: url_GetAttendee_606775,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttendee_606788 = ref object of OpenApiRestCall_605589
proc url_DeleteAttendee_606790(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meetingId" in path, "`meetingId` is a required path parameter"
  assert "attendeeId" in path, "`attendeeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meetings/"),
               (kind: VariableSegment, value: "meetingId"),
               (kind: ConstantSegment, value: "/attendees/"),
               (kind: VariableSegment, value: "attendeeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAttendee_606789(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   attendeeId: JString (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `attendeeId` field"
  var valid_606791 = path.getOrDefault("attendeeId")
  valid_606791 = validateParameter(valid_606791, JString, required = true,
                                 default = nil)
  if valid_606791 != nil:
    section.add "attendeeId", valid_606791
  var valid_606792 = path.getOrDefault("meetingId")
  valid_606792 = validateParameter(valid_606792, JString, required = true,
                                 default = nil)
  if valid_606792 != nil:
    section.add "meetingId", valid_606792
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606793 = header.getOrDefault("X-Amz-Signature")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Signature", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Content-Sha256", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Date")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Date", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Credential")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Credential", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Security-Token")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Security-Token", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Algorithm")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Algorithm", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-SignedHeaders", valid_606799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606800: Call_DeleteAttendee_606788; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606800.validator(path, query, header, formData, body)
  let scheme = call_606800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606800.url(scheme.get, call_606800.host, call_606800.base,
                         call_606800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606800, url, valid)

proc call*(call_606801: Call_DeleteAttendee_606788; attendeeId: string;
          meetingId: string): Recallable =
  ## deleteAttendee
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_606802 = newJObject()
  add(path_606802, "attendeeId", newJString(attendeeId))
  add(path_606802, "meetingId", newJString(meetingId))
  result = call_606801.call(path_606802, nil, nil, nil, nil)

var deleteAttendee* = Call_DeleteAttendee_606788(name: "deleteAttendee",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees/{attendeeId}",
    validator: validate_DeleteAttendee_606789, base: "/", url: url_DeleteAttendee_606790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_606818 = ref object of OpenApiRestCall_605589
proc url_PutEventsConfiguration_606820(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEventsConfiguration_606819(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botId: JString (required)
  ##        : The bot ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botId` field"
  var valid_606821 = path.getOrDefault("botId")
  valid_606821 = validateParameter(valid_606821, JString, required = true,
                                 default = nil)
  if valid_606821 != nil:
    section.add "botId", valid_606821
  var valid_606822 = path.getOrDefault("accountId")
  valid_606822 = validateParameter(valid_606822, JString, required = true,
                                 default = nil)
  if valid_606822 != nil:
    section.add "accountId", valid_606822
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606823 = header.getOrDefault("X-Amz-Signature")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Signature", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Content-Sha256", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Date")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Date", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Credential")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Credential", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Security-Token")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Security-Token", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Algorithm")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Algorithm", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-SignedHeaders", valid_606829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606831: Call_PutEventsConfiguration_606818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_606831.validator(path, query, header, formData, body)
  let scheme = call_606831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606831.url(scheme.get, call_606831.host, call_606831.base,
                         call_606831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606831, url, valid)

proc call*(call_606832: Call_PutEventsConfiguration_606818; botId: string;
          body: JsonNode; accountId: string): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606833 = newJObject()
  var body_606834 = newJObject()
  add(path_606833, "botId", newJString(botId))
  if body != nil:
    body_606834 = body
  add(path_606833, "accountId", newJString(accountId))
  result = call_606832.call(path_606833, nil, nil, nil, body_606834)

var putEventsConfiguration* = Call_PutEventsConfiguration_606818(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_606819, base: "/",
    url: url_PutEventsConfiguration_606820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_606803 = ref object of OpenApiRestCall_605589
proc url_GetEventsConfiguration_606805(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventsConfiguration_606804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botId: JString (required)
  ##        : The bot ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botId` field"
  var valid_606806 = path.getOrDefault("botId")
  valid_606806 = validateParameter(valid_606806, JString, required = true,
                                 default = nil)
  if valid_606806 != nil:
    section.add "botId", valid_606806
  var valid_606807 = path.getOrDefault("accountId")
  valid_606807 = validateParameter(valid_606807, JString, required = true,
                                 default = nil)
  if valid_606807 != nil:
    section.add "accountId", valid_606807
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606808 = header.getOrDefault("X-Amz-Signature")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Signature", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Content-Sha256", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Date")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Date", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Credential")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Credential", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Security-Token")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Security-Token", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Algorithm")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Algorithm", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-SignedHeaders", valid_606814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606815: Call_GetEventsConfiguration_606803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_606815.validator(path, query, header, formData, body)
  let scheme = call_606815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606815.url(scheme.get, call_606815.host, call_606815.base,
                         call_606815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606815, url, valid)

proc call*(call_606816: Call_GetEventsConfiguration_606803; botId: string;
          accountId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606817 = newJObject()
  add(path_606817, "botId", newJString(botId))
  add(path_606817, "accountId", newJString(accountId))
  result = call_606816.call(path_606817, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_606803(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_606804, base: "/",
    url: url_GetEventsConfiguration_606805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_606835 = ref object of OpenApiRestCall_605589
proc url_DeleteEventsConfiguration_606837(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEventsConfiguration_606836(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botId: JString (required)
  ##        : The bot ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botId` field"
  var valid_606838 = path.getOrDefault("botId")
  valid_606838 = validateParameter(valid_606838, JString, required = true,
                                 default = nil)
  if valid_606838 != nil:
    section.add "botId", valid_606838
  var valid_606839 = path.getOrDefault("accountId")
  valid_606839 = validateParameter(valid_606839, JString, required = true,
                                 default = nil)
  if valid_606839 != nil:
    section.add "accountId", valid_606839
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606840 = header.getOrDefault("X-Amz-Signature")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Signature", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Content-Sha256", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Date")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Date", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Credential")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Credential", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Security-Token")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Security-Token", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Algorithm")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Algorithm", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-SignedHeaders", valid_606846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606847: Call_DeleteEventsConfiguration_606835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_606847.validator(path, query, header, formData, body)
  let scheme = call_606847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606847.url(scheme.get, call_606847.host, call_606847.base,
                         call_606847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606847, url, valid)

proc call*(call_606848: Call_DeleteEventsConfiguration_606835; botId: string;
          accountId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_606849 = newJObject()
  add(path_606849, "botId", newJString(botId))
  add(path_606849, "accountId", newJString(accountId))
  result = call_606848.call(path_606849, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_606835(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_606836, base: "/",
    url: url_DeleteEventsConfiguration_606837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMeeting_606850 = ref object of OpenApiRestCall_605589
proc url_GetMeeting_606852(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meetingId" in path, "`meetingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meetings/"),
               (kind: VariableSegment, value: "meetingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMeeting_606851(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_606853 = path.getOrDefault("meetingId")
  valid_606853 = validateParameter(valid_606853, JString, required = true,
                                 default = nil)
  if valid_606853 != nil:
    section.add "meetingId", valid_606853
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606854 = header.getOrDefault("X-Amz-Signature")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Signature", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Content-Sha256", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Date")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Date", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Credential")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Credential", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Security-Token")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Security-Token", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Algorithm")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Algorithm", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-SignedHeaders", valid_606860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606861: Call_GetMeeting_606850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606861.validator(path, query, header, formData, body)
  let scheme = call_606861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606861.url(scheme.get, call_606861.host, call_606861.base,
                         call_606861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606861, url, valid)

proc call*(call_606862: Call_GetMeeting_606850; meetingId: string): Recallable =
  ## getMeeting
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_606863 = newJObject()
  add(path_606863, "meetingId", newJString(meetingId))
  result = call_606862.call(path_606863, nil, nil, nil, nil)

var getMeeting* = Call_GetMeeting_606850(name: "getMeeting",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/meetings/{meetingId}",
                                      validator: validate_GetMeeting_606851,
                                      base: "/", url: url_GetMeeting_606852,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMeeting_606864 = ref object of OpenApiRestCall_605589
proc url_DeleteMeeting_606866(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meetingId" in path, "`meetingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meetings/"),
               (kind: VariableSegment, value: "meetingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMeeting_606865(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_606867 = path.getOrDefault("meetingId")
  valid_606867 = validateParameter(valid_606867, JString, required = true,
                                 default = nil)
  if valid_606867 != nil:
    section.add "meetingId", valid_606867
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606868 = header.getOrDefault("X-Amz-Signature")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Signature", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Content-Sha256", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Date")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Date", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Credential")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Credential", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Security-Token")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Security-Token", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Algorithm")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Algorithm", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-SignedHeaders", valid_606874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606875: Call_DeleteMeeting_606864; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_606875.validator(path, query, header, formData, body)
  let scheme = call_606875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606875.url(scheme.get, call_606875.host, call_606875.base,
                         call_606875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606875, url, valid)

proc call*(call_606876: Call_DeleteMeeting_606864; meetingId: string): Recallable =
  ## deleteMeeting
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_606877 = newJObject()
  add(path_606877, "meetingId", newJString(meetingId))
  result = call_606876.call(path_606877, nil, nil, nil, nil)

var deleteMeeting* = Call_DeleteMeeting_606864(name: "deleteMeeting",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}", validator: validate_DeleteMeeting_606865,
    base: "/", url: url_DeleteMeeting_606866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_606892 = ref object of OpenApiRestCall_605589
proc url_UpdatePhoneNumber_606894(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePhoneNumber_606893(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   phoneNumberId: JString (required)
  ##                : The phone number ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `phoneNumberId` field"
  var valid_606895 = path.getOrDefault("phoneNumberId")
  valid_606895 = validateParameter(valid_606895, JString, required = true,
                                 default = nil)
  if valid_606895 != nil:
    section.add "phoneNumberId", valid_606895
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606896 = header.getOrDefault("X-Amz-Signature")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-Signature", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Content-Sha256", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Date")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Date", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Credential")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Credential", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Security-Token")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Security-Token", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Algorithm")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Algorithm", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-SignedHeaders", valid_606902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606904: Call_UpdatePhoneNumber_606892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_606904.validator(path, query, header, formData, body)
  let scheme = call_606904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606904.url(scheme.get, call_606904.host, call_606904.base,
                         call_606904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606904, url, valid)

proc call*(call_606905: Call_UpdatePhoneNumber_606892; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_606906 = newJObject()
  var body_606907 = newJObject()
  add(path_606906, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_606907 = body
  result = call_606905.call(path_606906, nil, nil, nil, body_606907)

var updatePhoneNumber* = Call_UpdatePhoneNumber_606892(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_606893, base: "/",
    url: url_UpdatePhoneNumber_606894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_606878 = ref object of OpenApiRestCall_605589
proc url_GetPhoneNumber_606880(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPhoneNumber_606879(path: JsonNode; query: JsonNode;
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
  var valid_606881 = path.getOrDefault("phoneNumberId")
  valid_606881 = validateParameter(valid_606881, JString, required = true,
                                 default = nil)
  if valid_606881 != nil:
    section.add "phoneNumberId", valid_606881
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606882 = header.getOrDefault("X-Amz-Signature")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Signature", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Content-Sha256", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Date")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Date", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Credential")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Credential", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Security-Token")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Security-Token", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Algorithm")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Algorithm", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-SignedHeaders", valid_606888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606889: Call_GetPhoneNumber_606878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_606889.validator(path, query, header, formData, body)
  let scheme = call_606889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606889.url(scheme.get, call_606889.host, call_606889.base,
                         call_606889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606889, url, valid)

proc call*(call_606890: Call_GetPhoneNumber_606878; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_606891 = newJObject()
  add(path_606891, "phoneNumberId", newJString(phoneNumberId))
  result = call_606890.call(path_606891, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_606878(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_606879,
    base: "/", url: url_GetPhoneNumber_606880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_606908 = ref object of OpenApiRestCall_605589
proc url_DeletePhoneNumber_606910(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePhoneNumber_606909(path: JsonNode; query: JsonNode;
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
  var valid_606911 = path.getOrDefault("phoneNumberId")
  valid_606911 = validateParameter(valid_606911, JString, required = true,
                                 default = nil)
  if valid_606911 != nil:
    section.add "phoneNumberId", valid_606911
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606912 = header.getOrDefault("X-Amz-Signature")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Signature", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Content-Sha256", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Date")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Date", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Credential")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Credential", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Security-Token")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Security-Token", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Algorithm")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Algorithm", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-SignedHeaders", valid_606918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606919: Call_DeletePhoneNumber_606908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_606919.validator(path, query, header, formData, body)
  let scheme = call_606919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606919.url(scheme.get, call_606919.host, call_606919.base,
                         call_606919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606919, url, valid)

proc call*(call_606920: Call_DeletePhoneNumber_606908; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_606921 = newJObject()
  add(path_606921, "phoneNumberId", newJString(phoneNumberId))
  result = call_606920.call(path_606921, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_606908(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_606909, base: "/",
    url: url_DeletePhoneNumber_606910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_606937 = ref object of OpenApiRestCall_605589
proc url_UpdateRoom_606939(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoom_606938(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates room details, such as the room name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606940 = path.getOrDefault("accountId")
  valid_606940 = validateParameter(valid_606940, JString, required = true,
                                 default = nil)
  if valid_606940 != nil:
    section.add "accountId", valid_606940
  var valid_606941 = path.getOrDefault("roomId")
  valid_606941 = validateParameter(valid_606941, JString, required = true,
                                 default = nil)
  if valid_606941 != nil:
    section.add "roomId", valid_606941
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606942 = header.getOrDefault("X-Amz-Signature")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Signature", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Content-Sha256", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-Date")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Date", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Credential")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Credential", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Security-Token")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Security-Token", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Algorithm")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Algorithm", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-SignedHeaders", valid_606948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606950: Call_UpdateRoom_606937; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details, such as the room name.
  ## 
  let valid = call_606950.validator(path, query, header, formData, body)
  let scheme = call_606950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606950.url(scheme.get, call_606950.host, call_606950.base,
                         call_606950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606950, url, valid)

proc call*(call_606951: Call_UpdateRoom_606937; body: JsonNode; accountId: string;
          roomId: string): Recallable =
  ## updateRoom
  ## Updates room details, such as the room name.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_606952 = newJObject()
  var body_606953 = newJObject()
  if body != nil:
    body_606953 = body
  add(path_606952, "accountId", newJString(accountId))
  add(path_606952, "roomId", newJString(roomId))
  result = call_606951.call(path_606952, nil, nil, nil, body_606953)

var updateRoom* = Call_UpdateRoom_606937(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_UpdateRoom_606938,
                                      base: "/", url: url_UpdateRoom_606939,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_606922 = ref object of OpenApiRestCall_605589
proc url_GetRoom_606924(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoom_606923(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves room details, such as the room name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606925 = path.getOrDefault("accountId")
  valid_606925 = validateParameter(valid_606925, JString, required = true,
                                 default = nil)
  if valid_606925 != nil:
    section.add "accountId", valid_606925
  var valid_606926 = path.getOrDefault("roomId")
  valid_606926 = validateParameter(valid_606926, JString, required = true,
                                 default = nil)
  if valid_606926 != nil:
    section.add "roomId", valid_606926
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606927 = header.getOrDefault("X-Amz-Signature")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Signature", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Content-Sha256", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-Date")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Date", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Credential")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Credential", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Security-Token")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Security-Token", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Algorithm")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Algorithm", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-SignedHeaders", valid_606933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606934: Call_GetRoom_606922; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves room details, such as the room name.
  ## 
  let valid = call_606934.validator(path, query, header, formData, body)
  let scheme = call_606934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606934.url(scheme.get, call_606934.host, call_606934.base,
                         call_606934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606934, url, valid)

proc call*(call_606935: Call_GetRoom_606922; accountId: string; roomId: string): Recallable =
  ## getRoom
  ## Retrieves room details, such as the room name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_606936 = newJObject()
  add(path_606936, "accountId", newJString(accountId))
  add(path_606936, "roomId", newJString(roomId))
  result = call_606935.call(path_606936, nil, nil, nil, nil)

var getRoom* = Call_GetRoom_606922(name: "getRoom", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/rooms/{roomId}",
                                validator: validate_GetRoom_606923, base: "/",
                                url: url_GetRoom_606924,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_606954 = ref object of OpenApiRestCall_605589
proc url_DeleteRoom_606956(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoom_606955(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a chat room.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The chat room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_606957 = path.getOrDefault("accountId")
  valid_606957 = validateParameter(valid_606957, JString, required = true,
                                 default = nil)
  if valid_606957 != nil:
    section.add "accountId", valid_606957
  var valid_606958 = path.getOrDefault("roomId")
  valid_606958 = validateParameter(valid_606958, JString, required = true,
                                 default = nil)
  if valid_606958 != nil:
    section.add "roomId", valid_606958
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606959 = header.getOrDefault("X-Amz-Signature")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Signature", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Content-Sha256", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Date")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Date", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Credential")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Credential", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Security-Token")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Security-Token", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Algorithm")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Algorithm", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-SignedHeaders", valid_606965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606966: Call_DeleteRoom_606954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a chat room.
  ## 
  let valid = call_606966.validator(path, query, header, formData, body)
  let scheme = call_606966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606966.url(scheme.get, call_606966.host, call_606966.base,
                         call_606966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606966, url, valid)

proc call*(call_606967: Call_DeleteRoom_606954; accountId: string; roomId: string): Recallable =
  ## deleteRoom
  ## Deletes a chat room.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The chat room ID.
  var path_606968 = newJObject()
  add(path_606968, "accountId", newJString(accountId))
  add(path_606968, "roomId", newJString(roomId))
  result = call_606967.call(path_606968, nil, nil, nil, nil)

var deleteRoom* = Call_DeleteRoom_606954(name: "deleteRoom",
                                      meth: HttpMethod.HttpDelete,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_DeleteRoom_606955,
                                      base: "/", url: url_DeleteRoom_606956,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoomMembership_606969 = ref object of OpenApiRestCall_605589
proc url_UpdateRoomMembership_606971(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId"),
               (kind: ConstantSegment, value: "/memberships/"),
               (kind: VariableSegment, value: "memberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoomMembership_606970(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates room membership details, such as the member role. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The member ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606972 = path.getOrDefault("memberId")
  valid_606972 = validateParameter(valid_606972, JString, required = true,
                                 default = nil)
  if valid_606972 != nil:
    section.add "memberId", valid_606972
  var valid_606973 = path.getOrDefault("accountId")
  valid_606973 = validateParameter(valid_606973, JString, required = true,
                                 default = nil)
  if valid_606973 != nil:
    section.add "accountId", valid_606973
  var valid_606974 = path.getOrDefault("roomId")
  valid_606974 = validateParameter(valid_606974, JString, required = true,
                                 default = nil)
  if valid_606974 != nil:
    section.add "roomId", valid_606974
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606975 = header.getOrDefault("X-Amz-Signature")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Signature", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Content-Sha256", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Date")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Date", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-Credential")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-Credential", valid_606978
  var valid_606979 = header.getOrDefault("X-Amz-Security-Token")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "X-Amz-Security-Token", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-Algorithm")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Algorithm", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-SignedHeaders", valid_606981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606983: Call_UpdateRoomMembership_606969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room membership details, such as the member role. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ## 
  let valid = call_606983.validator(path, query, header, formData, body)
  let scheme = call_606983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606983.url(scheme.get, call_606983.host, call_606983.base,
                         call_606983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606983, url, valid)

proc call*(call_606984: Call_UpdateRoomMembership_606969; memberId: string;
          body: JsonNode; accountId: string; roomId: string): Recallable =
  ## updateRoomMembership
  ## Updates room membership details, such as the member role. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ##   memberId: string (required)
  ##           : The member ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_606985 = newJObject()
  var body_606986 = newJObject()
  add(path_606985, "memberId", newJString(memberId))
  if body != nil:
    body_606986 = body
  add(path_606985, "accountId", newJString(accountId))
  add(path_606985, "roomId", newJString(roomId))
  result = call_606984.call(path_606985, nil, nil, nil, body_606986)

var updateRoomMembership* = Call_UpdateRoomMembership_606969(
    name: "updateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_UpdateRoomMembership_606970, base: "/",
    url: url_UpdateRoomMembership_606971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomMembership_606987 = ref object of OpenApiRestCall_605589
proc url_DeleteRoomMembership_606989(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "roomId" in path, "`roomId` is a required path parameter"
  assert "memberId" in path, "`memberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/rooms/"),
               (kind: VariableSegment, value: "roomId"),
               (kind: ConstantSegment, value: "/memberships/"),
               (kind: VariableSegment, value: "memberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoomMembership_606988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a member from a chat room.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   memberId: JString (required)
  ##           : The member ID (user ID or bot ID).
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: JString (required)
  ##         : The room ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `memberId` field"
  var valid_606990 = path.getOrDefault("memberId")
  valid_606990 = validateParameter(valid_606990, JString, required = true,
                                 default = nil)
  if valid_606990 != nil:
    section.add "memberId", valid_606990
  var valid_606991 = path.getOrDefault("accountId")
  valid_606991 = validateParameter(valid_606991, JString, required = true,
                                 default = nil)
  if valid_606991 != nil:
    section.add "accountId", valid_606991
  var valid_606992 = path.getOrDefault("roomId")
  valid_606992 = validateParameter(valid_606992, JString, required = true,
                                 default = nil)
  if valid_606992 != nil:
    section.add "roomId", valid_606992
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606993 = header.getOrDefault("X-Amz-Signature")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-Signature", valid_606993
  var valid_606994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Content-Sha256", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Date")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Date", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Credential")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Credential", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Security-Token")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Security-Token", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Algorithm")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Algorithm", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-SignedHeaders", valid_606999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607000: Call_DeleteRoomMembership_606987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a member from a chat room.
  ## 
  let valid = call_607000.validator(path, query, header, formData, body)
  let scheme = call_607000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607000.url(scheme.get, call_607000.host, call_607000.base,
                         call_607000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607000, url, valid)

proc call*(call_607001: Call_DeleteRoomMembership_606987; memberId: string;
          accountId: string; roomId: string): Recallable =
  ## deleteRoomMembership
  ## Removes a member from a chat room.
  ##   memberId: string (required)
  ##           : The member ID (user ID or bot ID).
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_607002 = newJObject()
  add(path_607002, "memberId", newJString(memberId))
  add(path_607002, "accountId", newJString(accountId))
  add(path_607002, "roomId", newJString(roomId))
  result = call_607001.call(path_607002, nil, nil, nil, nil)

var deleteRoomMembership* = Call_DeleteRoomMembership_606987(
    name: "deleteRoomMembership", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_DeleteRoomMembership_606988, base: "/",
    url: url_DeleteRoomMembership_606989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_607017 = ref object of OpenApiRestCall_605589
proc url_UpdateVoiceConnector_607019(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceConnector_607018(path: JsonNode; query: JsonNode;
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
  var valid_607020 = path.getOrDefault("voiceConnectorId")
  valid_607020 = validateParameter(valid_607020, JString, required = true,
                                 default = nil)
  if valid_607020 != nil:
    section.add "voiceConnectorId", valid_607020
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607021 = header.getOrDefault("X-Amz-Signature")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Signature", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Content-Sha256", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Date")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Date", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Credential")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Credential", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Security-Token")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Security-Token", valid_607025
  var valid_607026 = header.getOrDefault("X-Amz-Algorithm")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "X-Amz-Algorithm", valid_607026
  var valid_607027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607027 = validateParameter(valid_607027, JString, required = false,
                                 default = nil)
  if valid_607027 != nil:
    section.add "X-Amz-SignedHeaders", valid_607027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607029: Call_UpdateVoiceConnector_607017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607029.validator(path, query, header, formData, body)
  let scheme = call_607029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607029.url(scheme.get, call_607029.host, call_607029.base,
                         call_607029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607029, url, valid)

proc call*(call_607030: Call_UpdateVoiceConnector_607017; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607031 = newJObject()
  var body_607032 = newJObject()
  add(path_607031, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607032 = body
  result = call_607030.call(path_607031, nil, nil, nil, body_607032)

var updateVoiceConnector* = Call_UpdateVoiceConnector_607017(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_607018, base: "/",
    url: url_UpdateVoiceConnector_607019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_607003 = ref object of OpenApiRestCall_605589
proc url_GetVoiceConnector_607005(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnector_607004(path: JsonNode; query: JsonNode;
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
  var valid_607006 = path.getOrDefault("voiceConnectorId")
  valid_607006 = validateParameter(valid_607006, JString, required = true,
                                 default = nil)
  if valid_607006 != nil:
    section.add "voiceConnectorId", valid_607006
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607007 = header.getOrDefault("X-Amz-Signature")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Signature", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-Content-Sha256", valid_607008
  var valid_607009 = header.getOrDefault("X-Amz-Date")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Date", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Credential")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Credential", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Security-Token")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Security-Token", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-Algorithm")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-Algorithm", valid_607012
  var valid_607013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "X-Amz-SignedHeaders", valid_607013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607014: Call_GetVoiceConnector_607003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_607014.validator(path, query, header, formData, body)
  let scheme = call_607014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607014.url(scheme.get, call_607014.host, call_607014.base,
                         call_607014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607014, url, valid)

proc call*(call_607015: Call_GetVoiceConnector_607003; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607016 = newJObject()
  add(path_607016, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607015.call(path_607016, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_607003(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_607004, base: "/",
    url: url_GetVoiceConnector_607005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_607033 = ref object of OpenApiRestCall_605589
proc url_DeleteVoiceConnector_607035(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnector_607034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_607036 = path.getOrDefault("voiceConnectorId")
  valid_607036 = validateParameter(valid_607036, JString, required = true,
                                 default = nil)
  if valid_607036 != nil:
    section.add "voiceConnectorId", valid_607036
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607037 = header.getOrDefault("X-Amz-Signature")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Signature", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Content-Sha256", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Date")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Date", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-Credential")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-Credential", valid_607040
  var valid_607041 = header.getOrDefault("X-Amz-Security-Token")
  valid_607041 = validateParameter(valid_607041, JString, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "X-Amz-Security-Token", valid_607041
  var valid_607042 = header.getOrDefault("X-Amz-Algorithm")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "X-Amz-Algorithm", valid_607042
  var valid_607043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-SignedHeaders", valid_607043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607044: Call_DeleteVoiceConnector_607033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  let valid = call_607044.validator(path, query, header, formData, body)
  let scheme = call_607044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607044.url(scheme.get, call_607044.host, call_607044.base,
                         call_607044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607044, url, valid)

proc call*(call_607045: Call_DeleteVoiceConnector_607033; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607046 = newJObject()
  add(path_607046, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607045.call(path_607046, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_607033(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_607034, base: "/",
    url: url_DeleteVoiceConnector_607035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnectorGroup_607061 = ref object of OpenApiRestCall_605589
proc url_UpdateVoiceConnectorGroup_607063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorGroupId" in path,
        "`voiceConnectorGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connector-groups/"),
               (kind: VariableSegment, value: "voiceConnectorGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceConnectorGroup_607062(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_607064 = path.getOrDefault("voiceConnectorGroupId")
  valid_607064 = validateParameter(valid_607064, JString, required = true,
                                 default = nil)
  if valid_607064 != nil:
    section.add "voiceConnectorGroupId", valid_607064
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607065 = header.getOrDefault("X-Amz-Signature")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Signature", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Content-Sha256", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-Date")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Date", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-Credential")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Credential", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-Security-Token")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-Security-Token", valid_607069
  var valid_607070 = header.getOrDefault("X-Amz-Algorithm")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-Algorithm", valid_607070
  var valid_607071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-SignedHeaders", valid_607071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607073: Call_UpdateVoiceConnectorGroup_607061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  let valid = call_607073.validator(path, query, header, formData, body)
  let scheme = call_607073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607073.url(scheme.get, call_607073.host, call_607073.base,
                         call_607073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607073, url, valid)

proc call*(call_607074: Call_UpdateVoiceConnectorGroup_607061;
          voiceConnectorGroupId: string; body: JsonNode): Recallable =
  ## updateVoiceConnectorGroup
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   body: JObject (required)
  var path_607075 = newJObject()
  var body_607076 = newJObject()
  add(path_607075, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  if body != nil:
    body_607076 = body
  result = call_607074.call(path_607075, nil, nil, nil, body_607076)

var updateVoiceConnectorGroup* = Call_UpdateVoiceConnectorGroup_607061(
    name: "updateVoiceConnectorGroup", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_UpdateVoiceConnectorGroup_607062, base: "/",
    url: url_UpdateVoiceConnectorGroup_607063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorGroup_607047 = ref object of OpenApiRestCall_605589
proc url_GetVoiceConnectorGroup_607049(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorGroupId" in path,
        "`voiceConnectorGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connector-groups/"),
               (kind: VariableSegment, value: "voiceConnectorGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorGroup_607048(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_607050 = path.getOrDefault("voiceConnectorGroupId")
  valid_607050 = validateParameter(valid_607050, JString, required = true,
                                 default = nil)
  if valid_607050 != nil:
    section.add "voiceConnectorGroupId", valid_607050
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607051 = header.getOrDefault("X-Amz-Signature")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "X-Amz-Signature", valid_607051
  var valid_607052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "X-Amz-Content-Sha256", valid_607052
  var valid_607053 = header.getOrDefault("X-Amz-Date")
  valid_607053 = validateParameter(valid_607053, JString, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "X-Amz-Date", valid_607053
  var valid_607054 = header.getOrDefault("X-Amz-Credential")
  valid_607054 = validateParameter(valid_607054, JString, required = false,
                                 default = nil)
  if valid_607054 != nil:
    section.add "X-Amz-Credential", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-Security-Token")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Security-Token", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Algorithm")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Algorithm", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-SignedHeaders", valid_607057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607058: Call_GetVoiceConnectorGroup_607047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  let valid = call_607058.validator(path, query, header, formData, body)
  let scheme = call_607058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607058.url(scheme.get, call_607058.host, call_607058.base,
                         call_607058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607058, url, valid)

proc call*(call_607059: Call_GetVoiceConnectorGroup_607047;
          voiceConnectorGroupId: string): Recallable =
  ## getVoiceConnectorGroup
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_607060 = newJObject()
  add(path_607060, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_607059.call(path_607060, nil, nil, nil, nil)

var getVoiceConnectorGroup* = Call_GetVoiceConnectorGroup_607047(
    name: "getVoiceConnectorGroup", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_GetVoiceConnectorGroup_607048, base: "/",
    url: url_GetVoiceConnectorGroup_607049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorGroup_607077 = ref object of OpenApiRestCall_605589
proc url_DeleteVoiceConnectorGroup_607079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorGroupId" in path,
        "`voiceConnectorGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connector-groups/"),
               (kind: VariableSegment, value: "voiceConnectorGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorGroup_607078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_607080 = path.getOrDefault("voiceConnectorGroupId")
  valid_607080 = validateParameter(valid_607080, JString, required = true,
                                 default = nil)
  if valid_607080 != nil:
    section.add "voiceConnectorGroupId", valid_607080
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607081 = header.getOrDefault("X-Amz-Signature")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Signature", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Content-Sha256", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-Date")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-Date", valid_607083
  var valid_607084 = header.getOrDefault("X-Amz-Credential")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "X-Amz-Credential", valid_607084
  var valid_607085 = header.getOrDefault("X-Amz-Security-Token")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Security-Token", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-Algorithm")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-Algorithm", valid_607086
  var valid_607087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-SignedHeaders", valid_607087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607088: Call_DeleteVoiceConnectorGroup_607077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  let valid = call_607088.validator(path, query, header, formData, body)
  let scheme = call_607088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607088.url(scheme.get, call_607088.host, call_607088.base,
                         call_607088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607088, url, valid)

proc call*(call_607089: Call_DeleteVoiceConnectorGroup_607077;
          voiceConnectorGroupId: string): Recallable =
  ## deleteVoiceConnectorGroup
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_607090 = newJObject()
  add(path_607090, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_607089.call(path_607090, nil, nil, nil, nil)

var deleteVoiceConnectorGroup* = Call_DeleteVoiceConnectorGroup_607077(
    name: "deleteVoiceConnectorGroup", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_DeleteVoiceConnectorGroup_607078, base: "/",
    url: url_DeleteVoiceConnectorGroup_607079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_607105 = ref object of OpenApiRestCall_605589
proc url_PutVoiceConnectorOrigination_607107(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorOrigination_607106(path: JsonNode; query: JsonNode;
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
  var valid_607108 = path.getOrDefault("voiceConnectorId")
  valid_607108 = validateParameter(valid_607108, JString, required = true,
                                 default = nil)
  if valid_607108 != nil:
    section.add "voiceConnectorId", valid_607108
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607109 = header.getOrDefault("X-Amz-Signature")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Signature", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Content-Sha256", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Date")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Date", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Credential")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Credential", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Security-Token")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Security-Token", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Algorithm")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Algorithm", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-SignedHeaders", valid_607115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607117: Call_PutVoiceConnectorOrigination_607105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607117.validator(path, query, header, formData, body)
  let scheme = call_607117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607117.url(scheme.get, call_607117.host, call_607117.base,
                         call_607117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607117, url, valid)

proc call*(call_607118: Call_PutVoiceConnectorOrigination_607105;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607119 = newJObject()
  var body_607120 = newJObject()
  add(path_607119, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607120 = body
  result = call_607118.call(path_607119, nil, nil, nil, body_607120)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_607105(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_607106, base: "/",
    url: url_PutVoiceConnectorOrigination_607107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_607091 = ref object of OpenApiRestCall_605589
proc url_GetVoiceConnectorOrigination_607093(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorOrigination_607092(path: JsonNode; query: JsonNode;
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
  var valid_607094 = path.getOrDefault("voiceConnectorId")
  valid_607094 = validateParameter(valid_607094, JString, required = true,
                                 default = nil)
  if valid_607094 != nil:
    section.add "voiceConnectorId", valid_607094
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607095 = header.getOrDefault("X-Amz-Signature")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Signature", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Content-Sha256", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Date")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Date", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Credential")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Credential", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-Security-Token")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-Security-Token", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-Algorithm")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-Algorithm", valid_607100
  var valid_607101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "X-Amz-SignedHeaders", valid_607101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607102: Call_GetVoiceConnectorOrigination_607091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607102.validator(path, query, header, formData, body)
  let scheme = call_607102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607102.url(scheme.get, call_607102.host, call_607102.base,
                         call_607102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607102, url, valid)

proc call*(call_607103: Call_GetVoiceConnectorOrigination_607091;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607104 = newJObject()
  add(path_607104, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607103.call(path_607104, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_607091(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_607092, base: "/",
    url: url_GetVoiceConnectorOrigination_607093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_607121 = ref object of OpenApiRestCall_605589
proc url_DeleteVoiceConnectorOrigination_607123(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorOrigination_607122(path: JsonNode;
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
  var valid_607124 = path.getOrDefault("voiceConnectorId")
  valid_607124 = validateParameter(valid_607124, JString, required = true,
                                 default = nil)
  if valid_607124 != nil:
    section.add "voiceConnectorId", valid_607124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607125 = header.getOrDefault("X-Amz-Signature")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Signature", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Content-Sha256", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-Date")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-Date", valid_607127
  var valid_607128 = header.getOrDefault("X-Amz-Credential")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Credential", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Security-Token")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Security-Token", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Algorithm")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Algorithm", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-SignedHeaders", valid_607131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607132: Call_DeleteVoiceConnectorOrigination_607121;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607132.validator(path, query, header, formData, body)
  let scheme = call_607132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607132.url(scheme.get, call_607132.host, call_607132.base,
                         call_607132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607132, url, valid)

proc call*(call_607133: Call_DeleteVoiceConnectorOrigination_607121;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607134 = newJObject()
  add(path_607134, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607133.call(path_607134, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_607121(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_607122, base: "/",
    url: url_DeleteVoiceConnectorOrigination_607123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorStreamingConfiguration_607149 = ref object of OpenApiRestCall_605589
proc url_PutVoiceConnectorStreamingConfiguration_607151(protocol: Scheme;
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
               (kind: ConstantSegment, value: "/streaming-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorStreamingConfiguration_607150(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_607152 = path.getOrDefault("voiceConnectorId")
  valid_607152 = validateParameter(valid_607152, JString, required = true,
                                 default = nil)
  if valid_607152 != nil:
    section.add "voiceConnectorId", valid_607152
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607153 = header.getOrDefault("X-Amz-Signature")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Signature", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Content-Sha256", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-Date")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-Date", valid_607155
  var valid_607156 = header.getOrDefault("X-Amz-Credential")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "X-Amz-Credential", valid_607156
  var valid_607157 = header.getOrDefault("X-Amz-Security-Token")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-Security-Token", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-Algorithm")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Algorithm", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-SignedHeaders", valid_607159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607161: Call_PutVoiceConnectorStreamingConfiguration_607149;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_607161.validator(path, query, header, formData, body)
  let scheme = call_607161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607161.url(scheme.get, call_607161.host, call_607161.base,
                         call_607161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607161, url, valid)

proc call*(call_607162: Call_PutVoiceConnectorStreamingConfiguration_607149;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorStreamingConfiguration
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607163 = newJObject()
  var body_607164 = newJObject()
  add(path_607163, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607164 = body
  result = call_607162.call(path_607163, nil, nil, nil, body_607164)

var putVoiceConnectorStreamingConfiguration* = Call_PutVoiceConnectorStreamingConfiguration_607149(
    name: "putVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_PutVoiceConnectorStreamingConfiguration_607150, base: "/",
    url: url_PutVoiceConnectorStreamingConfiguration_607151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorStreamingConfiguration_607135 = ref object of OpenApiRestCall_605589
proc url_GetVoiceConnectorStreamingConfiguration_607137(protocol: Scheme;
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
               (kind: ConstantSegment, value: "/streaming-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorStreamingConfiguration_607136(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_607138 = path.getOrDefault("voiceConnectorId")
  valid_607138 = validateParameter(valid_607138, JString, required = true,
                                 default = nil)
  if valid_607138 != nil:
    section.add "voiceConnectorId", valid_607138
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607139 = header.getOrDefault("X-Amz-Signature")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "X-Amz-Signature", valid_607139
  var valid_607140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-Content-Sha256", valid_607140
  var valid_607141 = header.getOrDefault("X-Amz-Date")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Date", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Credential")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Credential", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-Security-Token")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Security-Token", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-Algorithm")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Algorithm", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-SignedHeaders", valid_607145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607146: Call_GetVoiceConnectorStreamingConfiguration_607135;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_607146.validator(path, query, header, formData, body)
  let scheme = call_607146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607146.url(scheme.get, call_607146.host, call_607146.base,
                         call_607146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607146, url, valid)

proc call*(call_607147: Call_GetVoiceConnectorStreamingConfiguration_607135;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorStreamingConfiguration
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607148 = newJObject()
  add(path_607148, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607147.call(path_607148, nil, nil, nil, nil)

var getVoiceConnectorStreamingConfiguration* = Call_GetVoiceConnectorStreamingConfiguration_607135(
    name: "getVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_GetVoiceConnectorStreamingConfiguration_607136, base: "/",
    url: url_GetVoiceConnectorStreamingConfiguration_607137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorStreamingConfiguration_607165 = ref object of OpenApiRestCall_605589
proc url_DeleteVoiceConnectorStreamingConfiguration_607167(protocol: Scheme;
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
               (kind: ConstantSegment, value: "/streaming-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorStreamingConfiguration_607166(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_607168 = path.getOrDefault("voiceConnectorId")
  valid_607168 = validateParameter(valid_607168, JString, required = true,
                                 default = nil)
  if valid_607168 != nil:
    section.add "voiceConnectorId", valid_607168
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607169 = header.getOrDefault("X-Amz-Signature")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "X-Amz-Signature", valid_607169
  var valid_607170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "X-Amz-Content-Sha256", valid_607170
  var valid_607171 = header.getOrDefault("X-Amz-Date")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "X-Amz-Date", valid_607171
  var valid_607172 = header.getOrDefault("X-Amz-Credential")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "X-Amz-Credential", valid_607172
  var valid_607173 = header.getOrDefault("X-Amz-Security-Token")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-Security-Token", valid_607173
  var valid_607174 = header.getOrDefault("X-Amz-Algorithm")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-Algorithm", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-SignedHeaders", valid_607175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607176: Call_DeleteVoiceConnectorStreamingConfiguration_607165;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607176.validator(path, query, header, formData, body)
  let scheme = call_607176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607176.url(scheme.get, call_607176.host, call_607176.base,
                         call_607176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607176, url, valid)

proc call*(call_607177: Call_DeleteVoiceConnectorStreamingConfiguration_607165;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorStreamingConfiguration
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607178 = newJObject()
  add(path_607178, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607177.call(path_607178, nil, nil, nil, nil)

var deleteVoiceConnectorStreamingConfiguration* = Call_DeleteVoiceConnectorStreamingConfiguration_607165(
    name: "deleteVoiceConnectorStreamingConfiguration",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_DeleteVoiceConnectorStreamingConfiguration_607166,
    base: "/", url: url_DeleteVoiceConnectorStreamingConfiguration_607167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_607193 = ref object of OpenApiRestCall_605589
proc url_PutVoiceConnectorTermination_607195(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorTermination_607194(path: JsonNode; query: JsonNode;
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
  var valid_607196 = path.getOrDefault("voiceConnectorId")
  valid_607196 = validateParameter(valid_607196, JString, required = true,
                                 default = nil)
  if valid_607196 != nil:
    section.add "voiceConnectorId", valid_607196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607197 = header.getOrDefault("X-Amz-Signature")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Signature", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Content-Sha256", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-Date")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Date", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Credential")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Credential", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Security-Token")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Security-Token", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Algorithm")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Algorithm", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-SignedHeaders", valid_607203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607205: Call_PutVoiceConnectorTermination_607193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607205.validator(path, query, header, formData, body)
  let scheme = call_607205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607205.url(scheme.get, call_607205.host, call_607205.base,
                         call_607205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607205, url, valid)

proc call*(call_607206: Call_PutVoiceConnectorTermination_607193;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607207 = newJObject()
  var body_607208 = newJObject()
  add(path_607207, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607208 = body
  result = call_607206.call(path_607207, nil, nil, nil, body_607208)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_607193(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_607194, base: "/",
    url: url_PutVoiceConnectorTermination_607195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_607179 = ref object of OpenApiRestCall_605589
proc url_GetVoiceConnectorTermination_607181(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorTermination_607180(path: JsonNode; query: JsonNode;
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
  var valid_607182 = path.getOrDefault("voiceConnectorId")
  valid_607182 = validateParameter(valid_607182, JString, required = true,
                                 default = nil)
  if valid_607182 != nil:
    section.add "voiceConnectorId", valid_607182
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607183 = header.getOrDefault("X-Amz-Signature")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Signature", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Content-Sha256", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Date")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Date", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Credential")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Credential", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Security-Token")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Security-Token", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Algorithm")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Algorithm", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-SignedHeaders", valid_607189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607190: Call_GetVoiceConnectorTermination_607179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607190.validator(path, query, header, formData, body)
  let scheme = call_607190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607190.url(scheme.get, call_607190.host, call_607190.base,
                         call_607190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607190, url, valid)

proc call*(call_607191: Call_GetVoiceConnectorTermination_607179;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607192 = newJObject()
  add(path_607192, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607191.call(path_607192, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_607179(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_607180, base: "/",
    url: url_GetVoiceConnectorTermination_607181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_607209 = ref object of OpenApiRestCall_605589
proc url_DeleteVoiceConnectorTermination_607211(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorTermination_607210(path: JsonNode;
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
  var valid_607212 = path.getOrDefault("voiceConnectorId")
  valid_607212 = validateParameter(valid_607212, JString, required = true,
                                 default = nil)
  if valid_607212 != nil:
    section.add "voiceConnectorId", valid_607212
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607213 = header.getOrDefault("X-Amz-Signature")
  valid_607213 = validateParameter(valid_607213, JString, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "X-Amz-Signature", valid_607213
  var valid_607214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "X-Amz-Content-Sha256", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Date")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Date", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Credential")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Credential", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Security-Token")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Security-Token", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Algorithm")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Algorithm", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-SignedHeaders", valid_607219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607220: Call_DeleteVoiceConnectorTermination_607209;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607220.validator(path, query, header, formData, body)
  let scheme = call_607220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607220.url(scheme.get, call_607220.host, call_607220.base,
                         call_607220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607220, url, valid)

proc call*(call_607221: Call_DeleteVoiceConnectorTermination_607209;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607222 = newJObject()
  add(path_607222, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607221.call(path_607222, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_607209(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_607210, base: "/",
    url: url_DeleteVoiceConnectorTermination_607211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_607223 = ref object of OpenApiRestCall_605589
proc url_DeleteVoiceConnectorTerminationCredentials_607225(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorTerminationCredentials_607224(path: JsonNode;
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
  var valid_607226 = path.getOrDefault("voiceConnectorId")
  valid_607226 = validateParameter(valid_607226, JString, required = true,
                                 default = nil)
  if valid_607226 != nil:
    section.add "voiceConnectorId", valid_607226
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607227 = query.getOrDefault("operation")
  valid_607227 = validateParameter(valid_607227, JString, required = true,
                                 default = newJString("delete"))
  if valid_607227 != nil:
    section.add "operation", valid_607227
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607228 = header.getOrDefault("X-Amz-Signature")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "X-Amz-Signature", valid_607228
  var valid_607229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-Content-Sha256", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Date")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Date", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Credential")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Credential", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Security-Token")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Security-Token", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Algorithm")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Algorithm", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-SignedHeaders", valid_607234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607236: Call_DeleteVoiceConnectorTerminationCredentials_607223;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_607236.validator(path, query, header, formData, body)
  let scheme = call_607236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607236.url(scheme.get, call_607236.host, call_607236.base,
                         call_607236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607236, url, valid)

proc call*(call_607237: Call_DeleteVoiceConnectorTerminationCredentials_607223;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607238 = newJObject()
  var query_607239 = newJObject()
  var body_607240 = newJObject()
  add(query_607239, "operation", newJString(operation))
  add(path_607238, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607240 = body
  result = call_607237.call(path_607238, query_607239, nil, nil, body_607240)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_607223(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_607224,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_607225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_607241 = ref object of OpenApiRestCall_605589
proc url_DisassociatePhoneNumberFromUser_607243(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociatePhoneNumberFromUser_607242(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_607244 = path.getOrDefault("userId")
  valid_607244 = validateParameter(valid_607244, JString, required = true,
                                 default = nil)
  if valid_607244 != nil:
    section.add "userId", valid_607244
  var valid_607245 = path.getOrDefault("accountId")
  valid_607245 = validateParameter(valid_607245, JString, required = true,
                                 default = nil)
  if valid_607245 != nil:
    section.add "accountId", valid_607245
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607246 = query.getOrDefault("operation")
  valid_607246 = validateParameter(valid_607246, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_607246 != nil:
    section.add "operation", valid_607246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607247 = header.getOrDefault("X-Amz-Signature")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Signature", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Content-Sha256", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Date")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Date", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Credential")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Credential", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Security-Token")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Security-Token", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Algorithm")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Algorithm", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-SignedHeaders", valid_607253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607254: Call_DisassociatePhoneNumberFromUser_607241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_607254.validator(path, query, header, formData, body)
  let scheme = call_607254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607254.url(scheme.get, call_607254.host, call_607254.base,
                         call_607254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607254, url, valid)

proc call*(call_607255: Call_DisassociatePhoneNumberFromUser_607241;
          userId: string; accountId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607256 = newJObject()
  var query_607257 = newJObject()
  add(query_607257, "operation", newJString(operation))
  add(path_607256, "userId", newJString(userId))
  add(path_607256, "accountId", newJString(accountId))
  result = call_607255.call(path_607256, query_607257, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_607241(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_607242, base: "/",
    url: url_DisassociatePhoneNumberFromUser_607243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_607258 = ref object of OpenApiRestCall_605589
proc url_DisassociatePhoneNumbersFromVoiceConnector_607260(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociatePhoneNumbersFromVoiceConnector_607259(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_607261 = path.getOrDefault("voiceConnectorId")
  valid_607261 = validateParameter(valid_607261, JString, required = true,
                                 default = nil)
  if valid_607261 != nil:
    section.add "voiceConnectorId", valid_607261
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607262 = query.getOrDefault("operation")
  valid_607262 = validateParameter(valid_607262, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_607262 != nil:
    section.add "operation", valid_607262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607263 = header.getOrDefault("X-Amz-Signature")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Signature", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Content-Sha256", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Date")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Date", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Credential")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Credential", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Security-Token")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Security-Token", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Algorithm")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Algorithm", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-SignedHeaders", valid_607269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607271: Call_DisassociatePhoneNumbersFromVoiceConnector_607258;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607271.validator(path, query, header, formData, body)
  let scheme = call_607271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607271.url(scheme.get, call_607271.host, call_607271.base,
                         call_607271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607271, url, valid)

proc call*(call_607272: Call_DisassociatePhoneNumbersFromVoiceConnector_607258;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607273 = newJObject()
  var query_607274 = newJObject()
  var body_607275 = newJObject()
  add(query_607274, "operation", newJString(operation))
  add(path_607273, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607275 = body
  result = call_607272.call(path_607273, query_607274, nil, nil, body_607275)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_607258(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_607259,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_607260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_607276 = ref object of OpenApiRestCall_605589
proc url_DisassociatePhoneNumbersFromVoiceConnectorGroup_607278(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorGroupId" in path,
        "`voiceConnectorGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connector-groups/"),
               (kind: VariableSegment, value: "voiceConnectorGroupId"), (
        kind: ConstantSegment, value: "#operation=disassociate-phone-numbers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_607277(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_607279 = path.getOrDefault("voiceConnectorGroupId")
  valid_607279 = validateParameter(valid_607279, JString, required = true,
                                 default = nil)
  if valid_607279 != nil:
    section.add "voiceConnectorGroupId", valid_607279
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607280 = query.getOrDefault("operation")
  valid_607280 = validateParameter(valid_607280, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_607280 != nil:
    section.add "operation", valid_607280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607281 = header.getOrDefault("X-Amz-Signature")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Signature", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Content-Sha256", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-Date")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Date", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Credential")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Credential", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-Security-Token")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-Security-Token", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-Algorithm")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-Algorithm", valid_607286
  var valid_607287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "X-Amz-SignedHeaders", valid_607287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607289: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_607276;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_607289.validator(path, query, header, formData, body)
  let scheme = call_607289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607289.url(scheme.get, call_607289.host, call_607289.base,
                         call_607289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607289, url, valid)

proc call*(call_607290: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_607276;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnectorGroup
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_607291 = newJObject()
  var query_607292 = newJObject()
  var body_607293 = newJObject()
  add(path_607291, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_607292, "operation", newJString(operation))
  if body != nil:
    body_607293 = body
  result = call_607290.call(path_607291, query_607292, nil, nil, body_607293)

var disassociatePhoneNumbersFromVoiceConnectorGroup* = Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_607276(
    name: "disassociatePhoneNumbersFromVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_607277,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnectorGroup_607278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSigninDelegateGroupsFromAccount_607294 = ref object of OpenApiRestCall_605589
proc url_DisassociateSigninDelegateGroupsFromAccount_607296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"), (kind: ConstantSegment,
        value: "#operation=disassociate-signin-delegate-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateSigninDelegateGroupsFromAccount_607295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_607297 = path.getOrDefault("accountId")
  valid_607297 = validateParameter(valid_607297, JString, required = true,
                                 default = nil)
  if valid_607297 != nil:
    section.add "accountId", valid_607297
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607298 = query.getOrDefault("operation")
  valid_607298 = validateParameter(valid_607298, JString, required = true, default = newJString(
      "disassociate-signin-delegate-groups"))
  if valid_607298 != nil:
    section.add "operation", valid_607298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607299 = header.getOrDefault("X-Amz-Signature")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Signature", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Content-Sha256", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-Date")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Date", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Credential")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Credential", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Security-Token")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Security-Token", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-Algorithm")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-Algorithm", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-SignedHeaders", valid_607305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607307: Call_DisassociateSigninDelegateGroupsFromAccount_607294;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ## 
  let valid = call_607307.validator(path, query, header, formData, body)
  let scheme = call_607307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607307.url(scheme.get, call_607307.host, call_607307.base,
                         call_607307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607307, url, valid)

proc call*(call_607308: Call_DisassociateSigninDelegateGroupsFromAccount_607294;
          body: JsonNode; accountId: string;
          operation: string = "disassociate-signin-delegate-groups"): Recallable =
  ## disassociateSigninDelegateGroupsFromAccount
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607309 = newJObject()
  var query_607310 = newJObject()
  var body_607311 = newJObject()
  add(query_607310, "operation", newJString(operation))
  if body != nil:
    body_607311 = body
  add(path_607309, "accountId", newJString(accountId))
  result = call_607308.call(path_607309, query_607310, nil, nil, body_607311)

var disassociateSigninDelegateGroupsFromAccount* = Call_DisassociateSigninDelegateGroupsFromAccount_607294(
    name: "disassociateSigninDelegateGroupsFromAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts/{accountId}#operation=disassociate-signin-delegate-groups",
    validator: validate_DisassociateSigninDelegateGroupsFromAccount_607295,
    base: "/", url: url_DisassociateSigninDelegateGroupsFromAccount_607296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_607326 = ref object of OpenApiRestCall_605589
proc url_UpdateAccountSettings_607328(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAccountSettings_607327(path: JsonNode; query: JsonNode;
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
  var valid_607329 = path.getOrDefault("accountId")
  valid_607329 = validateParameter(valid_607329, JString, required = true,
                                 default = nil)
  if valid_607329 != nil:
    section.add "accountId", valid_607329
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607330 = header.getOrDefault("X-Amz-Signature")
  valid_607330 = validateParameter(valid_607330, JString, required = false,
                                 default = nil)
  if valid_607330 != nil:
    section.add "X-Amz-Signature", valid_607330
  var valid_607331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607331 = validateParameter(valid_607331, JString, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "X-Amz-Content-Sha256", valid_607331
  var valid_607332 = header.getOrDefault("X-Amz-Date")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "X-Amz-Date", valid_607332
  var valid_607333 = header.getOrDefault("X-Amz-Credential")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "X-Amz-Credential", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Security-Token")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Security-Token", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Algorithm")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Algorithm", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-SignedHeaders", valid_607336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607338: Call_UpdateAccountSettings_607326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_607338.validator(path, query, header, formData, body)
  let scheme = call_607338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607338.url(scheme.get, call_607338.host, call_607338.base,
                         call_607338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607338, url, valid)

proc call*(call_607339: Call_UpdateAccountSettings_607326; body: JsonNode;
          accountId: string): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607340 = newJObject()
  var body_607341 = newJObject()
  if body != nil:
    body_607341 = body
  add(path_607340, "accountId", newJString(accountId))
  result = call_607339.call(path_607340, nil, nil, nil, body_607341)

var updateAccountSettings* = Call_UpdateAccountSettings_607326(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_607327, base: "/",
    url: url_UpdateAccountSettings_607328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_607312 = ref object of OpenApiRestCall_605589
proc url_GetAccountSettings_607314(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccountSettings_607313(path: JsonNode; query: JsonNode;
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
  var valid_607315 = path.getOrDefault("accountId")
  valid_607315 = validateParameter(valid_607315, JString, required = true,
                                 default = nil)
  if valid_607315 != nil:
    section.add "accountId", valid_607315
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607316 = header.getOrDefault("X-Amz-Signature")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-Signature", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Content-Sha256", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-Date")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-Date", valid_607318
  var valid_607319 = header.getOrDefault("X-Amz-Credential")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Credential", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Security-Token")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Security-Token", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Algorithm")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Algorithm", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-SignedHeaders", valid_607322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607323: Call_GetAccountSettings_607312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_607323.validator(path, query, header, formData, body)
  let scheme = call_607323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607323.url(scheme.get, call_607323.host, call_607323.base,
                         call_607323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607323, url, valid)

proc call*(call_607324: Call_GetAccountSettings_607312; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607325 = newJObject()
  add(path_607325, "accountId", newJString(accountId))
  result = call_607324.call(path_607325, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_607312(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_607313, base: "/",
    url: url_GetAccountSettings_607314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_607357 = ref object of OpenApiRestCall_605589
proc url_UpdateBot_607359(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBot_607358(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botId: JString (required)
  ##        : The bot ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botId` field"
  var valid_607360 = path.getOrDefault("botId")
  valid_607360 = validateParameter(valid_607360, JString, required = true,
                                 default = nil)
  if valid_607360 != nil:
    section.add "botId", valid_607360
  var valid_607361 = path.getOrDefault("accountId")
  valid_607361 = validateParameter(valid_607361, JString, required = true,
                                 default = nil)
  if valid_607361 != nil:
    section.add "accountId", valid_607361
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607362 = header.getOrDefault("X-Amz-Signature")
  valid_607362 = validateParameter(valid_607362, JString, required = false,
                                 default = nil)
  if valid_607362 != nil:
    section.add "X-Amz-Signature", valid_607362
  var valid_607363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607363 = validateParameter(valid_607363, JString, required = false,
                                 default = nil)
  if valid_607363 != nil:
    section.add "X-Amz-Content-Sha256", valid_607363
  var valid_607364 = header.getOrDefault("X-Amz-Date")
  valid_607364 = validateParameter(valid_607364, JString, required = false,
                                 default = nil)
  if valid_607364 != nil:
    section.add "X-Amz-Date", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Credential")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Credential", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Security-Token")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Security-Token", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Algorithm")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Algorithm", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-SignedHeaders", valid_607368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607370: Call_UpdateBot_607357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_607370.validator(path, query, header, formData, body)
  let scheme = call_607370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607370.url(scheme.get, call_607370.host, call_607370.base,
                         call_607370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607370, url, valid)

proc call*(call_607371: Call_UpdateBot_607357; botId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607372 = newJObject()
  var body_607373 = newJObject()
  add(path_607372, "botId", newJString(botId))
  if body != nil:
    body_607373 = body
  add(path_607372, "accountId", newJString(accountId))
  result = call_607371.call(path_607372, nil, nil, nil, body_607373)

var updateBot* = Call_UpdateBot_607357(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_607358,
                                    base: "/", url: url_UpdateBot_607359,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_607342 = ref object of OpenApiRestCall_605589
proc url_GetBot_607344(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBot_607343(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botId: JString (required)
  ##        : The bot ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botId` field"
  var valid_607345 = path.getOrDefault("botId")
  valid_607345 = validateParameter(valid_607345, JString, required = true,
                                 default = nil)
  if valid_607345 != nil:
    section.add "botId", valid_607345
  var valid_607346 = path.getOrDefault("accountId")
  valid_607346 = validateParameter(valid_607346, JString, required = true,
                                 default = nil)
  if valid_607346 != nil:
    section.add "accountId", valid_607346
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607347 = header.getOrDefault("X-Amz-Signature")
  valid_607347 = validateParameter(valid_607347, JString, required = false,
                                 default = nil)
  if valid_607347 != nil:
    section.add "X-Amz-Signature", valid_607347
  var valid_607348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607348 = validateParameter(valid_607348, JString, required = false,
                                 default = nil)
  if valid_607348 != nil:
    section.add "X-Amz-Content-Sha256", valid_607348
  var valid_607349 = header.getOrDefault("X-Amz-Date")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Date", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Credential")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Credential", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Security-Token")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Security-Token", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Algorithm")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Algorithm", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-SignedHeaders", valid_607353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607354: Call_GetBot_607342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_607354.validator(path, query, header, formData, body)
  let scheme = call_607354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607354.url(scheme.get, call_607354.host, call_607354.base,
                         call_607354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607354, url, valid)

proc call*(call_607355: Call_GetBot_607342; botId: string; accountId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607356 = newJObject()
  add(path_607356, "botId", newJString(botId))
  add(path_607356, "accountId", newJString(accountId))
  result = call_607355.call(path_607356, nil, nil, nil, nil)

var getBot* = Call_GetBot_607342(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_607343, base: "/",
                              url: url_GetBot_607344,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_607386 = ref object of OpenApiRestCall_605589
proc url_UpdateGlobalSettings_607388(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGlobalSettings_607387(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607389 = header.getOrDefault("X-Amz-Signature")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-Signature", valid_607389
  var valid_607390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607390 = validateParameter(valid_607390, JString, required = false,
                                 default = nil)
  if valid_607390 != nil:
    section.add "X-Amz-Content-Sha256", valid_607390
  var valid_607391 = header.getOrDefault("X-Amz-Date")
  valid_607391 = validateParameter(valid_607391, JString, required = false,
                                 default = nil)
  if valid_607391 != nil:
    section.add "X-Amz-Date", valid_607391
  var valid_607392 = header.getOrDefault("X-Amz-Credential")
  valid_607392 = validateParameter(valid_607392, JString, required = false,
                                 default = nil)
  if valid_607392 != nil:
    section.add "X-Amz-Credential", valid_607392
  var valid_607393 = header.getOrDefault("X-Amz-Security-Token")
  valid_607393 = validateParameter(valid_607393, JString, required = false,
                                 default = nil)
  if valid_607393 != nil:
    section.add "X-Amz-Security-Token", valid_607393
  var valid_607394 = header.getOrDefault("X-Amz-Algorithm")
  valid_607394 = validateParameter(valid_607394, JString, required = false,
                                 default = nil)
  if valid_607394 != nil:
    section.add "X-Amz-Algorithm", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-SignedHeaders", valid_607395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607397: Call_UpdateGlobalSettings_607386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_607397.validator(path, query, header, formData, body)
  let scheme = call_607397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607397.url(scheme.get, call_607397.host, call_607397.base,
                         call_607397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607397, url, valid)

proc call*(call_607398: Call_UpdateGlobalSettings_607386; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_607399 = newJObject()
  if body != nil:
    body_607399 = body
  result = call_607398.call(nil, nil, nil, nil, body_607399)

var updateGlobalSettings* = Call_UpdateGlobalSettings_607386(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_607387, base: "/",
    url: url_UpdateGlobalSettings_607388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_607374 = ref object of OpenApiRestCall_605589
proc url_GetGlobalSettings_607376(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGlobalSettings_607375(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607377 = header.getOrDefault("X-Amz-Signature")
  valid_607377 = validateParameter(valid_607377, JString, required = false,
                                 default = nil)
  if valid_607377 != nil:
    section.add "X-Amz-Signature", valid_607377
  var valid_607378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607378 = validateParameter(valid_607378, JString, required = false,
                                 default = nil)
  if valid_607378 != nil:
    section.add "X-Amz-Content-Sha256", valid_607378
  var valid_607379 = header.getOrDefault("X-Amz-Date")
  valid_607379 = validateParameter(valid_607379, JString, required = false,
                                 default = nil)
  if valid_607379 != nil:
    section.add "X-Amz-Date", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-Credential")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Credential", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Security-Token")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Security-Token", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Algorithm")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Algorithm", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-SignedHeaders", valid_607383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607384: Call_GetGlobalSettings_607374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_607384.validator(path, query, header, formData, body)
  let scheme = call_607384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607384.url(scheme.get, call_607384.host, call_607384.base,
                         call_607384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607384, url, valid)

proc call*(call_607385: Call_GetGlobalSettings_607374): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_607385.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_607374(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_607375, base: "/",
    url: url_GetGlobalSettings_607376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_607400 = ref object of OpenApiRestCall_605589
proc url_GetPhoneNumberOrder_607402(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPhoneNumberOrder_607401(path: JsonNode; query: JsonNode;
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
  var valid_607403 = path.getOrDefault("phoneNumberOrderId")
  valid_607403 = validateParameter(valid_607403, JString, required = true,
                                 default = nil)
  if valid_607403 != nil:
    section.add "phoneNumberOrderId", valid_607403
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607404 = header.getOrDefault("X-Amz-Signature")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Signature", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Content-Sha256", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-Date")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-Date", valid_607406
  var valid_607407 = header.getOrDefault("X-Amz-Credential")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "X-Amz-Credential", valid_607407
  var valid_607408 = header.getOrDefault("X-Amz-Security-Token")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "X-Amz-Security-Token", valid_607408
  var valid_607409 = header.getOrDefault("X-Amz-Algorithm")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "X-Amz-Algorithm", valid_607409
  var valid_607410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "X-Amz-SignedHeaders", valid_607410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607411: Call_GetPhoneNumberOrder_607400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_607411.validator(path, query, header, formData, body)
  let scheme = call_607411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607411.url(scheme.get, call_607411.host, call_607411.base,
                         call_607411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607411, url, valid)

proc call*(call_607412: Call_GetPhoneNumberOrder_607400; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_607413 = newJObject()
  add(path_607413, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_607412.call(path_607413, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_607400(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_607401, base: "/",
    url: url_GetPhoneNumberOrder_607402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumberSettings_607426 = ref object of OpenApiRestCall_605589
proc url_UpdatePhoneNumberSettings_607428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePhoneNumberSettings_607427(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607429 = header.getOrDefault("X-Amz-Signature")
  valid_607429 = validateParameter(valid_607429, JString, required = false,
                                 default = nil)
  if valid_607429 != nil:
    section.add "X-Amz-Signature", valid_607429
  var valid_607430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Content-Sha256", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-Date")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-Date", valid_607431
  var valid_607432 = header.getOrDefault("X-Amz-Credential")
  valid_607432 = validateParameter(valid_607432, JString, required = false,
                                 default = nil)
  if valid_607432 != nil:
    section.add "X-Amz-Credential", valid_607432
  var valid_607433 = header.getOrDefault("X-Amz-Security-Token")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "X-Amz-Security-Token", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-Algorithm")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-Algorithm", valid_607434
  var valid_607435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-SignedHeaders", valid_607435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607437: Call_UpdatePhoneNumberSettings_607426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ## 
  let valid = call_607437.validator(path, query, header, formData, body)
  let scheme = call_607437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607437.url(scheme.get, call_607437.host, call_607437.base,
                         call_607437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607437, url, valid)

proc call*(call_607438: Call_UpdatePhoneNumberSettings_607426; body: JsonNode): Recallable =
  ## updatePhoneNumberSettings
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ##   body: JObject (required)
  var body_607439 = newJObject()
  if body != nil:
    body_607439 = body
  result = call_607438.call(nil, nil, nil, nil, body_607439)

var updatePhoneNumberSettings* = Call_UpdatePhoneNumberSettings_607426(
    name: "updatePhoneNumberSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_UpdatePhoneNumberSettings_607427, base: "/",
    url: url_UpdatePhoneNumberSettings_607428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberSettings_607414 = ref object of OpenApiRestCall_605589
proc url_GetPhoneNumberSettings_607416(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPhoneNumberSettings_607415(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607417 = header.getOrDefault("X-Amz-Signature")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Signature", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Content-Sha256", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-Date")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-Date", valid_607419
  var valid_607420 = header.getOrDefault("X-Amz-Credential")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-Credential", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Security-Token")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Security-Token", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-Algorithm")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-Algorithm", valid_607422
  var valid_607423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607423 = validateParameter(valid_607423, JString, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "X-Amz-SignedHeaders", valid_607423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607424: Call_GetPhoneNumberSettings_607414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  let valid = call_607424.validator(path, query, header, formData, body)
  let scheme = call_607424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607424.url(scheme.get, call_607424.host, call_607424.base,
                         call_607424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607424, url, valid)

proc call*(call_607425: Call_GetPhoneNumberSettings_607414): Recallable =
  ## getPhoneNumberSettings
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  result = call_607425.call(nil, nil, nil, nil, nil)

var getPhoneNumberSettings* = Call_GetPhoneNumberSettings_607414(
    name: "getPhoneNumberSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_GetPhoneNumberSettings_607415, base: "/",
    url: url_GetPhoneNumberSettings_607416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_607455 = ref object of OpenApiRestCall_605589
proc url_UpdateUser_607457(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_607456(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_607458 = path.getOrDefault("userId")
  valid_607458 = validateParameter(valid_607458, JString, required = true,
                                 default = nil)
  if valid_607458 != nil:
    section.add "userId", valid_607458
  var valid_607459 = path.getOrDefault("accountId")
  valid_607459 = validateParameter(valid_607459, JString, required = true,
                                 default = nil)
  if valid_607459 != nil:
    section.add "accountId", valid_607459
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607460 = header.getOrDefault("X-Amz-Signature")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "X-Amz-Signature", valid_607460
  var valid_607461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "X-Amz-Content-Sha256", valid_607461
  var valid_607462 = header.getOrDefault("X-Amz-Date")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "X-Amz-Date", valid_607462
  var valid_607463 = header.getOrDefault("X-Amz-Credential")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "X-Amz-Credential", valid_607463
  var valid_607464 = header.getOrDefault("X-Amz-Security-Token")
  valid_607464 = validateParameter(valid_607464, JString, required = false,
                                 default = nil)
  if valid_607464 != nil:
    section.add "X-Amz-Security-Token", valid_607464
  var valid_607465 = header.getOrDefault("X-Amz-Algorithm")
  valid_607465 = validateParameter(valid_607465, JString, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "X-Amz-Algorithm", valid_607465
  var valid_607466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "X-Amz-SignedHeaders", valid_607466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607468: Call_UpdateUser_607455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_607468.validator(path, query, header, formData, body)
  let scheme = call_607468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607468.url(scheme.get, call_607468.host, call_607468.base,
                         call_607468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607468, url, valid)

proc call*(call_607469: Call_UpdateUser_607455; userId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607470 = newJObject()
  var body_607471 = newJObject()
  add(path_607470, "userId", newJString(userId))
  if body != nil:
    body_607471 = body
  add(path_607470, "accountId", newJString(accountId))
  result = call_607469.call(path_607470, nil, nil, nil, body_607471)

var updateUser* = Call_UpdateUser_607455(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_607456,
                                      base: "/", url: url_UpdateUser_607457,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_607440 = ref object of OpenApiRestCall_605589
proc url_GetUser_607442(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUser_607441(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_607443 = path.getOrDefault("userId")
  valid_607443 = validateParameter(valid_607443, JString, required = true,
                                 default = nil)
  if valid_607443 != nil:
    section.add "userId", valid_607443
  var valid_607444 = path.getOrDefault("accountId")
  valid_607444 = validateParameter(valid_607444, JString, required = true,
                                 default = nil)
  if valid_607444 != nil:
    section.add "accountId", valid_607444
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607445 = header.getOrDefault("X-Amz-Signature")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-Signature", valid_607445
  var valid_607446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "X-Amz-Content-Sha256", valid_607446
  var valid_607447 = header.getOrDefault("X-Amz-Date")
  valid_607447 = validateParameter(valid_607447, JString, required = false,
                                 default = nil)
  if valid_607447 != nil:
    section.add "X-Amz-Date", valid_607447
  var valid_607448 = header.getOrDefault("X-Amz-Credential")
  valid_607448 = validateParameter(valid_607448, JString, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "X-Amz-Credential", valid_607448
  var valid_607449 = header.getOrDefault("X-Amz-Security-Token")
  valid_607449 = validateParameter(valid_607449, JString, required = false,
                                 default = nil)
  if valid_607449 != nil:
    section.add "X-Amz-Security-Token", valid_607449
  var valid_607450 = header.getOrDefault("X-Amz-Algorithm")
  valid_607450 = validateParameter(valid_607450, JString, required = false,
                                 default = nil)
  if valid_607450 != nil:
    section.add "X-Amz-Algorithm", valid_607450
  var valid_607451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607451 = validateParameter(valid_607451, JString, required = false,
                                 default = nil)
  if valid_607451 != nil:
    section.add "X-Amz-SignedHeaders", valid_607451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607452: Call_GetUser_607440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_607452.validator(path, query, header, formData, body)
  let scheme = call_607452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607452.url(scheme.get, call_607452.host, call_607452.base,
                         call_607452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607452, url, valid)

proc call*(call_607453: Call_GetUser_607440; userId: string; accountId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607454 = newJObject()
  add(path_607454, "userId", newJString(userId))
  add(path_607454, "accountId", newJString(accountId))
  result = call_607453.call(path_607454, nil, nil, nil, nil)

var getUser* = Call_GetUser_607440(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_607441, base: "/",
                                url: url_GetUser_607442,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_607487 = ref object of OpenApiRestCall_605589
proc url_UpdateUserSettings_607489(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserSettings_607488(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_607490 = path.getOrDefault("userId")
  valid_607490 = validateParameter(valid_607490, JString, required = true,
                                 default = nil)
  if valid_607490 != nil:
    section.add "userId", valid_607490
  var valid_607491 = path.getOrDefault("accountId")
  valid_607491 = validateParameter(valid_607491, JString, required = true,
                                 default = nil)
  if valid_607491 != nil:
    section.add "accountId", valid_607491
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607492 = header.getOrDefault("X-Amz-Signature")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "X-Amz-Signature", valid_607492
  var valid_607493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "X-Amz-Content-Sha256", valid_607493
  var valid_607494 = header.getOrDefault("X-Amz-Date")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "X-Amz-Date", valid_607494
  var valid_607495 = header.getOrDefault("X-Amz-Credential")
  valid_607495 = validateParameter(valid_607495, JString, required = false,
                                 default = nil)
  if valid_607495 != nil:
    section.add "X-Amz-Credential", valid_607495
  var valid_607496 = header.getOrDefault("X-Amz-Security-Token")
  valid_607496 = validateParameter(valid_607496, JString, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "X-Amz-Security-Token", valid_607496
  var valid_607497 = header.getOrDefault("X-Amz-Algorithm")
  valid_607497 = validateParameter(valid_607497, JString, required = false,
                                 default = nil)
  if valid_607497 != nil:
    section.add "X-Amz-Algorithm", valid_607497
  var valid_607498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607498 = validateParameter(valid_607498, JString, required = false,
                                 default = nil)
  if valid_607498 != nil:
    section.add "X-Amz-SignedHeaders", valid_607498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607500: Call_UpdateUserSettings_607487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_607500.validator(path, query, header, formData, body)
  let scheme = call_607500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607500.url(scheme.get, call_607500.host, call_607500.base,
                         call_607500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607500, url, valid)

proc call*(call_607501: Call_UpdateUserSettings_607487; userId: string;
          body: JsonNode; accountId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607502 = newJObject()
  var body_607503 = newJObject()
  add(path_607502, "userId", newJString(userId))
  if body != nil:
    body_607503 = body
  add(path_607502, "accountId", newJString(accountId))
  result = call_607501.call(path_607502, nil, nil, nil, body_607503)

var updateUserSettings* = Call_UpdateUserSettings_607487(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_607488, base: "/",
    url: url_UpdateUserSettings_607489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_607472 = ref object of OpenApiRestCall_605589
proc url_GetUserSettings_607474(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUserSettings_607473(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_607475 = path.getOrDefault("userId")
  valid_607475 = validateParameter(valid_607475, JString, required = true,
                                 default = nil)
  if valid_607475 != nil:
    section.add "userId", valid_607475
  var valid_607476 = path.getOrDefault("accountId")
  valid_607476 = validateParameter(valid_607476, JString, required = true,
                                 default = nil)
  if valid_607476 != nil:
    section.add "accountId", valid_607476
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607477 = header.getOrDefault("X-Amz-Signature")
  valid_607477 = validateParameter(valid_607477, JString, required = false,
                                 default = nil)
  if valid_607477 != nil:
    section.add "X-Amz-Signature", valid_607477
  var valid_607478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607478 = validateParameter(valid_607478, JString, required = false,
                                 default = nil)
  if valid_607478 != nil:
    section.add "X-Amz-Content-Sha256", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-Date")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-Date", valid_607479
  var valid_607480 = header.getOrDefault("X-Amz-Credential")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "X-Amz-Credential", valid_607480
  var valid_607481 = header.getOrDefault("X-Amz-Security-Token")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "X-Amz-Security-Token", valid_607481
  var valid_607482 = header.getOrDefault("X-Amz-Algorithm")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-Algorithm", valid_607482
  var valid_607483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "X-Amz-SignedHeaders", valid_607483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607484: Call_GetUserSettings_607472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_607484.validator(path, query, header, formData, body)
  let scheme = call_607484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607484.url(scheme.get, call_607484.host, call_607484.base,
                         call_607484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607484, url, valid)

proc call*(call_607485: Call_GetUserSettings_607472; userId: string;
          accountId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607486 = newJObject()
  add(path_607486, "userId", newJString(userId))
  add(path_607486, "accountId", newJString(accountId))
  result = call_607485.call(path_607486, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_607472(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_607473, base: "/", url: url_GetUserSettings_607474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorLoggingConfiguration_607518 = ref object of OpenApiRestCall_605589
proc url_PutVoiceConnectorLoggingConfiguration_607520(protocol: Scheme;
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
               (kind: ConstantSegment, value: "/logging-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorLoggingConfiguration_607519(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_607521 = path.getOrDefault("voiceConnectorId")
  valid_607521 = validateParameter(valid_607521, JString, required = true,
                                 default = nil)
  if valid_607521 != nil:
    section.add "voiceConnectorId", valid_607521
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607522 = header.getOrDefault("X-Amz-Signature")
  valid_607522 = validateParameter(valid_607522, JString, required = false,
                                 default = nil)
  if valid_607522 != nil:
    section.add "X-Amz-Signature", valid_607522
  var valid_607523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607523 = validateParameter(valid_607523, JString, required = false,
                                 default = nil)
  if valid_607523 != nil:
    section.add "X-Amz-Content-Sha256", valid_607523
  var valid_607524 = header.getOrDefault("X-Amz-Date")
  valid_607524 = validateParameter(valid_607524, JString, required = false,
                                 default = nil)
  if valid_607524 != nil:
    section.add "X-Amz-Date", valid_607524
  var valid_607525 = header.getOrDefault("X-Amz-Credential")
  valid_607525 = validateParameter(valid_607525, JString, required = false,
                                 default = nil)
  if valid_607525 != nil:
    section.add "X-Amz-Credential", valid_607525
  var valid_607526 = header.getOrDefault("X-Amz-Security-Token")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "X-Amz-Security-Token", valid_607526
  var valid_607527 = header.getOrDefault("X-Amz-Algorithm")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "X-Amz-Algorithm", valid_607527
  var valid_607528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607528 = validateParameter(valid_607528, JString, required = false,
                                 default = nil)
  if valid_607528 != nil:
    section.add "X-Amz-SignedHeaders", valid_607528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607530: Call_PutVoiceConnectorLoggingConfiguration_607518;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_607530.validator(path, query, header, formData, body)
  let scheme = call_607530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607530.url(scheme.get, call_607530.host, call_607530.base,
                         call_607530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607530, url, valid)

proc call*(call_607531: Call_PutVoiceConnectorLoggingConfiguration_607518;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorLoggingConfiguration
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607532 = newJObject()
  var body_607533 = newJObject()
  add(path_607532, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607533 = body
  result = call_607531.call(path_607532, nil, nil, nil, body_607533)

var putVoiceConnectorLoggingConfiguration* = Call_PutVoiceConnectorLoggingConfiguration_607518(
    name: "putVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_PutVoiceConnectorLoggingConfiguration_607519, base: "/",
    url: url_PutVoiceConnectorLoggingConfiguration_607520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorLoggingConfiguration_607504 = ref object of OpenApiRestCall_605589
proc url_GetVoiceConnectorLoggingConfiguration_607506(protocol: Scheme;
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
               (kind: ConstantSegment, value: "/logging-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorLoggingConfiguration_607505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_607507 = path.getOrDefault("voiceConnectorId")
  valid_607507 = validateParameter(valid_607507, JString, required = true,
                                 default = nil)
  if valid_607507 != nil:
    section.add "voiceConnectorId", valid_607507
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607508 = header.getOrDefault("X-Amz-Signature")
  valid_607508 = validateParameter(valid_607508, JString, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "X-Amz-Signature", valid_607508
  var valid_607509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607509 = validateParameter(valid_607509, JString, required = false,
                                 default = nil)
  if valid_607509 != nil:
    section.add "X-Amz-Content-Sha256", valid_607509
  var valid_607510 = header.getOrDefault("X-Amz-Date")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "X-Amz-Date", valid_607510
  var valid_607511 = header.getOrDefault("X-Amz-Credential")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "X-Amz-Credential", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Security-Token")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Security-Token", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Algorithm")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Algorithm", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-SignedHeaders", valid_607514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607515: Call_GetVoiceConnectorLoggingConfiguration_607504;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_607515.validator(path, query, header, formData, body)
  let scheme = call_607515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607515.url(scheme.get, call_607515.host, call_607515.base,
                         call_607515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607515, url, valid)

proc call*(call_607516: Call_GetVoiceConnectorLoggingConfiguration_607504;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorLoggingConfiguration
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607517 = newJObject()
  add(path_607517, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607516.call(path_607517, nil, nil, nil, nil)

var getVoiceConnectorLoggingConfiguration* = Call_GetVoiceConnectorLoggingConfiguration_607504(
    name: "getVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_GetVoiceConnectorLoggingConfiguration_607505, base: "/",
    url: url_GetVoiceConnectorLoggingConfiguration_607506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_607534 = ref object of OpenApiRestCall_605589
proc url_GetVoiceConnectorTerminationHealth_607536(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorTerminationHealth_607535(path: JsonNode;
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
  var valid_607537 = path.getOrDefault("voiceConnectorId")
  valid_607537 = validateParameter(valid_607537, JString, required = true,
                                 default = nil)
  if valid_607537 != nil:
    section.add "voiceConnectorId", valid_607537
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607538 = header.getOrDefault("X-Amz-Signature")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-Signature", valid_607538
  var valid_607539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "X-Amz-Content-Sha256", valid_607539
  var valid_607540 = header.getOrDefault("X-Amz-Date")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "X-Amz-Date", valid_607540
  var valid_607541 = header.getOrDefault("X-Amz-Credential")
  valid_607541 = validateParameter(valid_607541, JString, required = false,
                                 default = nil)
  if valid_607541 != nil:
    section.add "X-Amz-Credential", valid_607541
  var valid_607542 = header.getOrDefault("X-Amz-Security-Token")
  valid_607542 = validateParameter(valid_607542, JString, required = false,
                                 default = nil)
  if valid_607542 != nil:
    section.add "X-Amz-Security-Token", valid_607542
  var valid_607543 = header.getOrDefault("X-Amz-Algorithm")
  valid_607543 = validateParameter(valid_607543, JString, required = false,
                                 default = nil)
  if valid_607543 != nil:
    section.add "X-Amz-Algorithm", valid_607543
  var valid_607544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607544 = validateParameter(valid_607544, JString, required = false,
                                 default = nil)
  if valid_607544 != nil:
    section.add "X-Amz-SignedHeaders", valid_607544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607545: Call_GetVoiceConnectorTerminationHealth_607534;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607545.validator(path, query, header, formData, body)
  let scheme = call_607545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607545.url(scheme.get, call_607545.host, call_607545.base,
                         call_607545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607545, url, valid)

proc call*(call_607546: Call_GetVoiceConnectorTerminationHealth_607534;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607547 = newJObject()
  add(path_607547, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607546.call(path_607547, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_607534(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_607535, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_607536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_607548 = ref object of OpenApiRestCall_605589
proc url_InviteUsers_607550(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InviteUsers_607549(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_607551 = path.getOrDefault("accountId")
  valid_607551 = validateParameter(valid_607551, JString, required = true,
                                 default = nil)
  if valid_607551 != nil:
    section.add "accountId", valid_607551
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607552 = query.getOrDefault("operation")
  valid_607552 = validateParameter(valid_607552, JString, required = true,
                                 default = newJString("add"))
  if valid_607552 != nil:
    section.add "operation", valid_607552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607553 = header.getOrDefault("X-Amz-Signature")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Signature", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-Content-Sha256", valid_607554
  var valid_607555 = header.getOrDefault("X-Amz-Date")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "X-Amz-Date", valid_607555
  var valid_607556 = header.getOrDefault("X-Amz-Credential")
  valid_607556 = validateParameter(valid_607556, JString, required = false,
                                 default = nil)
  if valid_607556 != nil:
    section.add "X-Amz-Credential", valid_607556
  var valid_607557 = header.getOrDefault("X-Amz-Security-Token")
  valid_607557 = validateParameter(valid_607557, JString, required = false,
                                 default = nil)
  if valid_607557 != nil:
    section.add "X-Amz-Security-Token", valid_607557
  var valid_607558 = header.getOrDefault("X-Amz-Algorithm")
  valid_607558 = validateParameter(valid_607558, JString, required = false,
                                 default = nil)
  if valid_607558 != nil:
    section.add "X-Amz-Algorithm", valid_607558
  var valid_607559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607559 = validateParameter(valid_607559, JString, required = false,
                                 default = nil)
  if valid_607559 != nil:
    section.add "X-Amz-SignedHeaders", valid_607559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607561: Call_InviteUsers_607548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_607561.validator(path, query, header, formData, body)
  let scheme = call_607561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607561.url(scheme.get, call_607561.host, call_607561.base,
                         call_607561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607561, url, valid)

proc call*(call_607562: Call_InviteUsers_607548; body: JsonNode; accountId: string;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607563 = newJObject()
  var query_607564 = newJObject()
  var body_607565 = newJObject()
  add(query_607564, "operation", newJString(operation))
  if body != nil:
    body_607565 = body
  add(path_607563, "accountId", newJString(accountId))
  result = call_607562.call(path_607563, query_607564, nil, nil, body_607565)

var inviteUsers* = Call_InviteUsers_607548(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_607549,
                                        base: "/", url: url_InviteUsers_607550,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_607566 = ref object of OpenApiRestCall_605589
proc url_ListPhoneNumbers_607568(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumbers_607567(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   product-type: JString
  ##               : The phone number product type.
  ##   filter-name: JString
  ##              : The filter to use to limit the number of results.
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   status: JString
  ##         : The phone number status.
  ##   filter-value: JString
  ##               : The value to use for the filter.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_607569 = query.getOrDefault("MaxResults")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "MaxResults", valid_607569
  var valid_607570 = query.getOrDefault("NextToken")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "NextToken", valid_607570
  var valid_607571 = query.getOrDefault("product-type")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_607571 != nil:
    section.add "product-type", valid_607571
  var valid_607572 = query.getOrDefault("filter-name")
  valid_607572 = validateParameter(valid_607572, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_607572 != nil:
    section.add "filter-name", valid_607572
  var valid_607573 = query.getOrDefault("max-results")
  valid_607573 = validateParameter(valid_607573, JInt, required = false, default = nil)
  if valid_607573 != nil:
    section.add "max-results", valid_607573
  var valid_607574 = query.getOrDefault("status")
  valid_607574 = validateParameter(valid_607574, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_607574 != nil:
    section.add "status", valid_607574
  var valid_607575 = query.getOrDefault("filter-value")
  valid_607575 = validateParameter(valid_607575, JString, required = false,
                                 default = nil)
  if valid_607575 != nil:
    section.add "filter-value", valid_607575
  var valid_607576 = query.getOrDefault("next-token")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "next-token", valid_607576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607577 = header.getOrDefault("X-Amz-Signature")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "X-Amz-Signature", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Content-Sha256", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-Date")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-Date", valid_607579
  var valid_607580 = header.getOrDefault("X-Amz-Credential")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "X-Amz-Credential", valid_607580
  var valid_607581 = header.getOrDefault("X-Amz-Security-Token")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-Security-Token", valid_607581
  var valid_607582 = header.getOrDefault("X-Amz-Algorithm")
  valid_607582 = validateParameter(valid_607582, JString, required = false,
                                 default = nil)
  if valid_607582 != nil:
    section.add "X-Amz-Algorithm", valid_607582
  var valid_607583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "X-Amz-SignedHeaders", valid_607583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607584: Call_ListPhoneNumbers_607566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  let valid = call_607584.validator(path, query, header, formData, body)
  let scheme = call_607584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607584.url(scheme.get, call_607584.host, call_607584.base,
                         call_607584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607584, url, valid)

proc call*(call_607585: Call_ListPhoneNumbers_607566; MaxResults: string = "";
          NextToken: string = ""; productType: string = "BusinessCalling";
          filterName: string = "AccountId"; maxResults: int = 0;
          status: string = "AcquireInProgress"; filterValue: string = "";
          nextToken: string = ""): Recallable =
  ## listPhoneNumbers
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   productType: string
  ##              : The phone number product type.
  ##   filterName: string
  ##             : The filter to use to limit the number of results.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   status: string
  ##         : The phone number status.
  ##   filterValue: string
  ##              : The value to use for the filter.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var query_607586 = newJObject()
  add(query_607586, "MaxResults", newJString(MaxResults))
  add(query_607586, "NextToken", newJString(NextToken))
  add(query_607586, "product-type", newJString(productType))
  add(query_607586, "filter-name", newJString(filterName))
  add(query_607586, "max-results", newJInt(maxResults))
  add(query_607586, "status", newJString(status))
  add(query_607586, "filter-value", newJString(filterValue))
  add(query_607586, "next-token", newJString(nextToken))
  result = call_607585.call(nil, query_607586, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_607566(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_607567, base: "/",
    url: url_ListPhoneNumbers_607568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_607587 = ref object of OpenApiRestCall_605589
proc url_ListVoiceConnectorTerminationCredentials_607589(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVoiceConnectorTerminationCredentials_607588(path: JsonNode;
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
  var valid_607590 = path.getOrDefault("voiceConnectorId")
  valid_607590 = validateParameter(valid_607590, JString, required = true,
                                 default = nil)
  if valid_607590 != nil:
    section.add "voiceConnectorId", valid_607590
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607591 = header.getOrDefault("X-Amz-Signature")
  valid_607591 = validateParameter(valid_607591, JString, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "X-Amz-Signature", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Content-Sha256", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-Date")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-Date", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-Credential")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-Credential", valid_607594
  var valid_607595 = header.getOrDefault("X-Amz-Security-Token")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "X-Amz-Security-Token", valid_607595
  var valid_607596 = header.getOrDefault("X-Amz-Algorithm")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "X-Amz-Algorithm", valid_607596
  var valid_607597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607597 = validateParameter(valid_607597, JString, required = false,
                                 default = nil)
  if valid_607597 != nil:
    section.add "X-Amz-SignedHeaders", valid_607597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607598: Call_ListVoiceConnectorTerminationCredentials_607587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607598.validator(path, query, header, formData, body)
  let scheme = call_607598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607598.url(scheme.get, call_607598.host, call_607598.base,
                         call_607598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607598, url, valid)

proc call*(call_607599: Call_ListVoiceConnectorTerminationCredentials_607587;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_607600 = newJObject()
  add(path_607600, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_607599.call(path_607600, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_607587(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_607588,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_607589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_607601 = ref object of OpenApiRestCall_605589
proc url_LogoutUser_607603(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_LogoutUser_607602(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_607604 = path.getOrDefault("userId")
  valid_607604 = validateParameter(valid_607604, JString, required = true,
                                 default = nil)
  if valid_607604 != nil:
    section.add "userId", valid_607604
  var valid_607605 = path.getOrDefault("accountId")
  valid_607605 = validateParameter(valid_607605, JString, required = true,
                                 default = nil)
  if valid_607605 != nil:
    section.add "accountId", valid_607605
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607606 = query.getOrDefault("operation")
  valid_607606 = validateParameter(valid_607606, JString, required = true,
                                 default = newJString("logout"))
  if valid_607606 != nil:
    section.add "operation", valid_607606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607607 = header.getOrDefault("X-Amz-Signature")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Signature", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Content-Sha256", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-Date")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Date", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-Credential")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-Credential", valid_607610
  var valid_607611 = header.getOrDefault("X-Amz-Security-Token")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-Security-Token", valid_607611
  var valid_607612 = header.getOrDefault("X-Amz-Algorithm")
  valid_607612 = validateParameter(valid_607612, JString, required = false,
                                 default = nil)
  if valid_607612 != nil:
    section.add "X-Amz-Algorithm", valid_607612
  var valid_607613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607613 = validateParameter(valid_607613, JString, required = false,
                                 default = nil)
  if valid_607613 != nil:
    section.add "X-Amz-SignedHeaders", valid_607613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607614: Call_LogoutUser_607601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_607614.validator(path, query, header, formData, body)
  let scheme = call_607614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607614.url(scheme.get, call_607614.host, call_607614.base,
                         call_607614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607614, url, valid)

proc call*(call_607615: Call_LogoutUser_607601; userId: string; accountId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607616 = newJObject()
  var query_607617 = newJObject()
  add(query_607617, "operation", newJString(operation))
  add(path_607616, "userId", newJString(userId))
  add(path_607616, "accountId", newJString(accountId))
  result = call_607615.call(path_607616, query_607617, nil, nil, nil)

var logoutUser* = Call_LogoutUser_607601(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_607602,
                                      base: "/", url: url_LogoutUser_607603,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_607618 = ref object of OpenApiRestCall_605589
proc url_PutVoiceConnectorTerminationCredentials_607620(protocol: Scheme;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorTerminationCredentials_607619(path: JsonNode;
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
  var valid_607621 = path.getOrDefault("voiceConnectorId")
  valid_607621 = validateParameter(valid_607621, JString, required = true,
                                 default = nil)
  if valid_607621 != nil:
    section.add "voiceConnectorId", valid_607621
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607622 = query.getOrDefault("operation")
  valid_607622 = validateParameter(valid_607622, JString, required = true,
                                 default = newJString("put"))
  if valid_607622 != nil:
    section.add "operation", valid_607622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607623 = header.getOrDefault("X-Amz-Signature")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Signature", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Content-Sha256", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-Date")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-Date", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-Credential")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Credential", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Security-Token")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Security-Token", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-Algorithm")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-Algorithm", valid_607628
  var valid_607629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "X-Amz-SignedHeaders", valid_607629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607631: Call_PutVoiceConnectorTerminationCredentials_607618;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_607631.validator(path, query, header, formData, body)
  let scheme = call_607631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607631.url(scheme.get, call_607631.host, call_607631.base,
                         call_607631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607631, url, valid)

proc call*(call_607632: Call_PutVoiceConnectorTerminationCredentials_607618;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_607633 = newJObject()
  var query_607634 = newJObject()
  var body_607635 = newJObject()
  add(query_607634, "operation", newJString(operation))
  add(path_607633, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_607635 = body
  result = call_607632.call(path_607633, query_607634, nil, nil, body_607635)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_607618(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_607619, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_607620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_607636 = ref object of OpenApiRestCall_605589
proc url_RegenerateSecurityToken_607638(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegenerateSecurityToken_607637(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Regenerates the security token for a bot.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botId: JString (required)
  ##        : The bot ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botId` field"
  var valid_607639 = path.getOrDefault("botId")
  valid_607639 = validateParameter(valid_607639, JString, required = true,
                                 default = nil)
  if valid_607639 != nil:
    section.add "botId", valid_607639
  var valid_607640 = path.getOrDefault("accountId")
  valid_607640 = validateParameter(valid_607640, JString, required = true,
                                 default = nil)
  if valid_607640 != nil:
    section.add "accountId", valid_607640
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607641 = query.getOrDefault("operation")
  valid_607641 = validateParameter(valid_607641, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_607641 != nil:
    section.add "operation", valid_607641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607642 = header.getOrDefault("X-Amz-Signature")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "X-Amz-Signature", valid_607642
  var valid_607643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-Content-Sha256", valid_607643
  var valid_607644 = header.getOrDefault("X-Amz-Date")
  valid_607644 = validateParameter(valid_607644, JString, required = false,
                                 default = nil)
  if valid_607644 != nil:
    section.add "X-Amz-Date", valid_607644
  var valid_607645 = header.getOrDefault("X-Amz-Credential")
  valid_607645 = validateParameter(valid_607645, JString, required = false,
                                 default = nil)
  if valid_607645 != nil:
    section.add "X-Amz-Credential", valid_607645
  var valid_607646 = header.getOrDefault("X-Amz-Security-Token")
  valid_607646 = validateParameter(valid_607646, JString, required = false,
                                 default = nil)
  if valid_607646 != nil:
    section.add "X-Amz-Security-Token", valid_607646
  var valid_607647 = header.getOrDefault("X-Amz-Algorithm")
  valid_607647 = validateParameter(valid_607647, JString, required = false,
                                 default = nil)
  if valid_607647 != nil:
    section.add "X-Amz-Algorithm", valid_607647
  var valid_607648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607648 = validateParameter(valid_607648, JString, required = false,
                                 default = nil)
  if valid_607648 != nil:
    section.add "X-Amz-SignedHeaders", valid_607648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607649: Call_RegenerateSecurityToken_607636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_607649.validator(path, query, header, formData, body)
  let scheme = call_607649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607649.url(scheme.get, call_607649.host, call_607649.base,
                         call_607649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607649, url, valid)

proc call*(call_607650: Call_RegenerateSecurityToken_607636; botId: string;
          accountId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607651 = newJObject()
  var query_607652 = newJObject()
  add(path_607651, "botId", newJString(botId))
  add(query_607652, "operation", newJString(operation))
  add(path_607651, "accountId", newJString(accountId))
  result = call_607650.call(path_607651, query_607652, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_607636(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_607637, base: "/",
    url: url_RegenerateSecurityToken_607638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_607653 = ref object of OpenApiRestCall_605589
proc url_ResetPersonalPIN_607655(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ResetPersonalPIN_607654(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   userId: JString (required)
  ##         : The user ID.
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `userId` field"
  var valid_607656 = path.getOrDefault("userId")
  valid_607656 = validateParameter(valid_607656, JString, required = true,
                                 default = nil)
  if valid_607656 != nil:
    section.add "userId", valid_607656
  var valid_607657 = path.getOrDefault("accountId")
  valid_607657 = validateParameter(valid_607657, JString, required = true,
                                 default = nil)
  if valid_607657 != nil:
    section.add "accountId", valid_607657
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607658 = query.getOrDefault("operation")
  valid_607658 = validateParameter(valid_607658, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_607658 != nil:
    section.add "operation", valid_607658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607659 = header.getOrDefault("X-Amz-Signature")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "X-Amz-Signature", valid_607659
  var valid_607660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "X-Amz-Content-Sha256", valid_607660
  var valid_607661 = header.getOrDefault("X-Amz-Date")
  valid_607661 = validateParameter(valid_607661, JString, required = false,
                                 default = nil)
  if valid_607661 != nil:
    section.add "X-Amz-Date", valid_607661
  var valid_607662 = header.getOrDefault("X-Amz-Credential")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-Credential", valid_607662
  var valid_607663 = header.getOrDefault("X-Amz-Security-Token")
  valid_607663 = validateParameter(valid_607663, JString, required = false,
                                 default = nil)
  if valid_607663 != nil:
    section.add "X-Amz-Security-Token", valid_607663
  var valid_607664 = header.getOrDefault("X-Amz-Algorithm")
  valid_607664 = validateParameter(valid_607664, JString, required = false,
                                 default = nil)
  if valid_607664 != nil:
    section.add "X-Amz-Algorithm", valid_607664
  var valid_607665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-SignedHeaders", valid_607665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607666: Call_ResetPersonalPIN_607653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_607666.validator(path, query, header, formData, body)
  let scheme = call_607666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607666.url(scheme.get, call_607666.host, call_607666.base,
                         call_607666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607666, url, valid)

proc call*(call_607667: Call_ResetPersonalPIN_607653; userId: string;
          accountId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_607668 = newJObject()
  var query_607669 = newJObject()
  add(query_607669, "operation", newJString(operation))
  add(path_607668, "userId", newJString(userId))
  add(path_607668, "accountId", newJString(accountId))
  result = call_607667.call(path_607668, query_607669, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_607653(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_607654, base: "/",
    url: url_ResetPersonalPIN_607655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_607670 = ref object of OpenApiRestCall_605589
proc url_RestorePhoneNumber_607672(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RestorePhoneNumber_607671(path: JsonNode; query: JsonNode;
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
  var valid_607673 = path.getOrDefault("phoneNumberId")
  valid_607673 = validateParameter(valid_607673, JString, required = true,
                                 default = nil)
  if valid_607673 != nil:
    section.add "phoneNumberId", valid_607673
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_607674 = query.getOrDefault("operation")
  valid_607674 = validateParameter(valid_607674, JString, required = true,
                                 default = newJString("restore"))
  if valid_607674 != nil:
    section.add "operation", valid_607674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607675 = header.getOrDefault("X-Amz-Signature")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "X-Amz-Signature", valid_607675
  var valid_607676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "X-Amz-Content-Sha256", valid_607676
  var valid_607677 = header.getOrDefault("X-Amz-Date")
  valid_607677 = validateParameter(valid_607677, JString, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "X-Amz-Date", valid_607677
  var valid_607678 = header.getOrDefault("X-Amz-Credential")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "X-Amz-Credential", valid_607678
  var valid_607679 = header.getOrDefault("X-Amz-Security-Token")
  valid_607679 = validateParameter(valid_607679, JString, required = false,
                                 default = nil)
  if valid_607679 != nil:
    section.add "X-Amz-Security-Token", valid_607679
  var valid_607680 = header.getOrDefault("X-Amz-Algorithm")
  valid_607680 = validateParameter(valid_607680, JString, required = false,
                                 default = nil)
  if valid_607680 != nil:
    section.add "X-Amz-Algorithm", valid_607680
  var valid_607681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607681 = validateParameter(valid_607681, JString, required = false,
                                 default = nil)
  if valid_607681 != nil:
    section.add "X-Amz-SignedHeaders", valid_607681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607682: Call_RestorePhoneNumber_607670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_607682.validator(path, query, header, formData, body)
  let scheme = call_607682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607682.url(scheme.get, call_607682.host, call_607682.base,
                         call_607682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607682, url, valid)

proc call*(call_607683: Call_RestorePhoneNumber_607670; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_607684 = newJObject()
  var query_607685 = newJObject()
  add(path_607684, "phoneNumberId", newJString(phoneNumberId))
  add(query_607685, "operation", newJString(operation))
  result = call_607683.call(path_607684, query_607685, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_607670(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_607671, base: "/",
    url: url_RestorePhoneNumber_607672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_607686 = ref object of OpenApiRestCall_605589
proc url_SearchAvailablePhoneNumbers_607688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchAvailablePhoneNumbers_607687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches phone numbers that can be ordered.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   state: JString
  ##        : The state used to filter results.
  ##   area-code: JString
  ##            : The area code used to filter results.
  ##   toll-free-prefix: JString
  ##                   : The toll-free prefix that you use to filter results.
  ##   type: JString (required)
  ##   city: JString
  ##       : The city used to filter results.
  ##   country: JString
  ##          : The country used to filter results.
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_607689 = query.getOrDefault("state")
  valid_607689 = validateParameter(valid_607689, JString, required = false,
                                 default = nil)
  if valid_607689 != nil:
    section.add "state", valid_607689
  var valid_607690 = query.getOrDefault("area-code")
  valid_607690 = validateParameter(valid_607690, JString, required = false,
                                 default = nil)
  if valid_607690 != nil:
    section.add "area-code", valid_607690
  var valid_607691 = query.getOrDefault("toll-free-prefix")
  valid_607691 = validateParameter(valid_607691, JString, required = false,
                                 default = nil)
  if valid_607691 != nil:
    section.add "toll-free-prefix", valid_607691
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_607692 = query.getOrDefault("type")
  valid_607692 = validateParameter(valid_607692, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_607692 != nil:
    section.add "type", valid_607692
  var valid_607693 = query.getOrDefault("city")
  valid_607693 = validateParameter(valid_607693, JString, required = false,
                                 default = nil)
  if valid_607693 != nil:
    section.add "city", valid_607693
  var valid_607694 = query.getOrDefault("country")
  valid_607694 = validateParameter(valid_607694, JString, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "country", valid_607694
  var valid_607695 = query.getOrDefault("max-results")
  valid_607695 = validateParameter(valid_607695, JInt, required = false, default = nil)
  if valid_607695 != nil:
    section.add "max-results", valid_607695
  var valid_607696 = query.getOrDefault("next-token")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "next-token", valid_607696
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607697 = header.getOrDefault("X-Amz-Signature")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Signature", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Content-Sha256", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Date")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Date", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Credential")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Credential", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-Security-Token")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-Security-Token", valid_607701
  var valid_607702 = header.getOrDefault("X-Amz-Algorithm")
  valid_607702 = validateParameter(valid_607702, JString, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "X-Amz-Algorithm", valid_607702
  var valid_607703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607703 = validateParameter(valid_607703, JString, required = false,
                                 default = nil)
  if valid_607703 != nil:
    section.add "X-Amz-SignedHeaders", valid_607703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607704: Call_SearchAvailablePhoneNumbers_607686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_607704.validator(path, query, header, formData, body)
  let scheme = call_607704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607704.url(scheme.get, call_607704.host, call_607704.base,
                         call_607704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607704, url, valid)

proc call*(call_607705: Call_SearchAvailablePhoneNumbers_607686;
          state: string = ""; areaCode: string = ""; tollFreePrefix: string = "";
          `type`: string = "phone-numbers"; city: string = ""; country: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## searchAvailablePhoneNumbers
  ## Searches phone numbers that can be ordered.
  ##   state: string
  ##        : The state used to filter results.
  ##   areaCode: string
  ##           : The area code used to filter results.
  ##   tollFreePrefix: string
  ##                 : The toll-free prefix that you use to filter results.
  ##   type: string (required)
  ##   city: string
  ##       : The city used to filter results.
  ##   country: string
  ##          : The country used to filter results.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var query_607706 = newJObject()
  add(query_607706, "state", newJString(state))
  add(query_607706, "area-code", newJString(areaCode))
  add(query_607706, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_607706, "type", newJString(`type`))
  add(query_607706, "city", newJString(city))
  add(query_607706, "country", newJString(country))
  add(query_607706, "max-results", newJInt(maxResults))
  add(query_607706, "next-token", newJString(nextToken))
  result = call_607705.call(nil, query_607706, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_607686(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_607687, base: "/",
    url: url_SearchAvailablePhoneNumbers_607688,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
