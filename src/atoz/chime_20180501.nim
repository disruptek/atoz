
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  Call_AssociatePhoneNumberWithUser_610996 = ref object of OpenApiRestCall_610658
proc url_AssociatePhoneNumberWithUser_610998(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociatePhoneNumberWithUser_610997(path: JsonNode; query: JsonNode;
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
  var valid_611124 = path.getOrDefault("userId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "userId", valid_611124
  var valid_611125 = path.getOrDefault("accountId")
  valid_611125 = validateParameter(valid_611125, JString, required = true,
                                 default = nil)
  if valid_611125 != nil:
    section.add "accountId", valid_611125
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611139 = query.getOrDefault("operation")
  valid_611139 = validateParameter(valid_611139, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_611139 != nil:
    section.add "operation", valid_611139
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
  var valid_611140 = header.getOrDefault("X-Amz-Signature")
  valid_611140 = validateParameter(valid_611140, JString, required = false,
                                 default = nil)
  if valid_611140 != nil:
    section.add "X-Amz-Signature", valid_611140
  var valid_611141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611141 = validateParameter(valid_611141, JString, required = false,
                                 default = nil)
  if valid_611141 != nil:
    section.add "X-Amz-Content-Sha256", valid_611141
  var valid_611142 = header.getOrDefault("X-Amz-Date")
  valid_611142 = validateParameter(valid_611142, JString, required = false,
                                 default = nil)
  if valid_611142 != nil:
    section.add "X-Amz-Date", valid_611142
  var valid_611143 = header.getOrDefault("X-Amz-Credential")
  valid_611143 = validateParameter(valid_611143, JString, required = false,
                                 default = nil)
  if valid_611143 != nil:
    section.add "X-Amz-Credential", valid_611143
  var valid_611144 = header.getOrDefault("X-Amz-Security-Token")
  valid_611144 = validateParameter(valid_611144, JString, required = false,
                                 default = nil)
  if valid_611144 != nil:
    section.add "X-Amz-Security-Token", valid_611144
  var valid_611145 = header.getOrDefault("X-Amz-Algorithm")
  valid_611145 = validateParameter(valid_611145, JString, required = false,
                                 default = nil)
  if valid_611145 != nil:
    section.add "X-Amz-Algorithm", valid_611145
  var valid_611146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611146 = validateParameter(valid_611146, JString, required = false,
                                 default = nil)
  if valid_611146 != nil:
    section.add "X-Amz-SignedHeaders", valid_611146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611170: Call_AssociatePhoneNumberWithUser_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_611170.validator(path, query, header, formData, body)
  let scheme = call_611170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611170.url(scheme.get, call_611170.host, call_611170.base,
                         call_611170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611170, url, valid)

proc call*(call_611241: Call_AssociatePhoneNumberWithUser_610996; userId: string;
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
  var path_611242 = newJObject()
  var query_611244 = newJObject()
  var body_611245 = newJObject()
  add(query_611244, "operation", newJString(operation))
  add(path_611242, "userId", newJString(userId))
  if body != nil:
    body_611245 = body
  add(path_611242, "accountId", newJString(accountId))
  result = call_611241.call(path_611242, query_611244, nil, nil, body_611245)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_610996(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_610997, base: "/",
    url: url_AssociatePhoneNumberWithUser_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_611284 = ref object of OpenApiRestCall_610658
proc url_AssociatePhoneNumbersWithVoiceConnector_611286(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociatePhoneNumbersWithVoiceConnector_611285(path: JsonNode;
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
  var valid_611287 = path.getOrDefault("voiceConnectorId")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "voiceConnectorId", valid_611287
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611288 = query.getOrDefault("operation")
  valid_611288 = validateParameter(valid_611288, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_611288 != nil:
    section.add "operation", valid_611288
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
  var valid_611289 = header.getOrDefault("X-Amz-Signature")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Signature", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Content-Sha256", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Date")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Date", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Credential")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Credential", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Security-Token")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Security-Token", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Algorithm")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Algorithm", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-SignedHeaders", valid_611295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611297: Call_AssociatePhoneNumbersWithVoiceConnector_611284;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_611297.validator(path, query, header, formData, body)
  let scheme = call_611297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611297.url(scheme.get, call_611297.host, call_611297.base,
                         call_611297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611297, url, valid)

proc call*(call_611298: Call_AssociatePhoneNumbersWithVoiceConnector_611284;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_611299 = newJObject()
  var query_611300 = newJObject()
  var body_611301 = newJObject()
  add(query_611300, "operation", newJString(operation))
  add(path_611299, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_611301 = body
  result = call_611298.call(path_611299, query_611300, nil, nil, body_611301)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_611284(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_611285, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_611286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnectorGroup_611302 = ref object of OpenApiRestCall_610658
proc url_AssociatePhoneNumbersWithVoiceConnectorGroup_611304(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociatePhoneNumbersWithVoiceConnectorGroup_611303(path: JsonNode;
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
  var valid_611305 = path.getOrDefault("voiceConnectorGroupId")
  valid_611305 = validateParameter(valid_611305, JString, required = true,
                                 default = nil)
  if valid_611305 != nil:
    section.add "voiceConnectorGroupId", valid_611305
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611306 = query.getOrDefault("operation")
  valid_611306 = validateParameter(valid_611306, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_611306 != nil:
    section.add "operation", valid_611306
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
  var valid_611307 = header.getOrDefault("X-Amz-Signature")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Signature", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Content-Sha256", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Date")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Date", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Credential")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Credential", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Security-Token")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Security-Token", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Algorithm")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Algorithm", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-SignedHeaders", valid_611313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611315: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_611302;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_611315.validator(path, query, header, formData, body)
  let scheme = call_611315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611315.url(scheme.get, call_611315.host, call_611315.base,
                         call_611315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611315, url, valid)

proc call*(call_611316: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_611302;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnectorGroup
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_611317 = newJObject()
  var query_611318 = newJObject()
  var body_611319 = newJObject()
  add(path_611317, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_611318, "operation", newJString(operation))
  if body != nil:
    body_611319 = body
  result = call_611316.call(path_611317, query_611318, nil, nil, body_611319)

var associatePhoneNumbersWithVoiceConnectorGroup* = Call_AssociatePhoneNumbersWithVoiceConnectorGroup_611302(
    name: "associatePhoneNumbersWithVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnectorGroup_611303,
    base: "/", url: url_AssociatePhoneNumbersWithVoiceConnectorGroup_611304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSigninDelegateGroupsWithAccount_611320 = ref object of OpenApiRestCall_610658
proc url_AssociateSigninDelegateGroupsWithAccount_611322(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateSigninDelegateGroupsWithAccount_611321(path: JsonNode;
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
  var valid_611323 = path.getOrDefault("accountId")
  valid_611323 = validateParameter(valid_611323, JString, required = true,
                                 default = nil)
  if valid_611323 != nil:
    section.add "accountId", valid_611323
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611324 = query.getOrDefault("operation")
  valid_611324 = validateParameter(valid_611324, JString, required = true, default = newJString(
      "associate-signin-delegate-groups"))
  if valid_611324 != nil:
    section.add "operation", valid_611324
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
  var valid_611325 = header.getOrDefault("X-Amz-Signature")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Signature", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Content-Sha256", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Date")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Date", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Credential")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Credential", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Security-Token")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Security-Token", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Algorithm")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Algorithm", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-SignedHeaders", valid_611331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611333: Call_AssociateSigninDelegateGroupsWithAccount_611320;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ## 
  let valid = call_611333.validator(path, query, header, formData, body)
  let scheme = call_611333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611333.url(scheme.get, call_611333.host, call_611333.base,
                         call_611333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611333, url, valid)

proc call*(call_611334: Call_AssociateSigninDelegateGroupsWithAccount_611320;
          body: JsonNode; accountId: string;
          operation: string = "associate-signin-delegate-groups"): Recallable =
  ## associateSigninDelegateGroupsWithAccount
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611335 = newJObject()
  var query_611336 = newJObject()
  var body_611337 = newJObject()
  add(query_611336, "operation", newJString(operation))
  if body != nil:
    body_611337 = body
  add(path_611335, "accountId", newJString(accountId))
  result = call_611334.call(path_611335, query_611336, nil, nil, body_611337)

var associateSigninDelegateGroupsWithAccount* = Call_AssociateSigninDelegateGroupsWithAccount_611320(
    name: "associateSigninDelegateGroupsWithAccount", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}#operation=associate-signin-delegate-groups",
    validator: validate_AssociateSigninDelegateGroupsWithAccount_611321,
    base: "/", url: url_AssociateSigninDelegateGroupsWithAccount_611322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateAttendee_611338 = ref object of OpenApiRestCall_610658
proc url_BatchCreateAttendee_611340(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchCreateAttendee_611339(path: JsonNode; query: JsonNode;
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
  var valid_611341 = path.getOrDefault("meetingId")
  valid_611341 = validateParameter(valid_611341, JString, required = true,
                                 default = nil)
  if valid_611341 != nil:
    section.add "meetingId", valid_611341
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611342 = query.getOrDefault("operation")
  valid_611342 = validateParameter(valid_611342, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_611342 != nil:
    section.add "operation", valid_611342
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
  var valid_611343 = header.getOrDefault("X-Amz-Signature")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Signature", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Content-Sha256", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Date")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Date", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Credential")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Credential", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Security-Token")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Security-Token", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Algorithm")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Algorithm", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-SignedHeaders", valid_611349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611351: Call_BatchCreateAttendee_611338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  let valid = call_611351.validator(path, query, header, formData, body)
  let scheme = call_611351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611351.url(scheme.get, call_611351.host, call_611351.base,
                         call_611351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611351, url, valid)

proc call*(call_611352: Call_BatchCreateAttendee_611338; body: JsonNode;
          meetingId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateAttendee
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_611353 = newJObject()
  var query_611354 = newJObject()
  var body_611355 = newJObject()
  add(query_611354, "operation", newJString(operation))
  if body != nil:
    body_611355 = body
  add(path_611353, "meetingId", newJString(meetingId))
  result = call_611352.call(path_611353, query_611354, nil, nil, body_611355)

var batchCreateAttendee* = Call_BatchCreateAttendee_611338(
    name: "batchCreateAttendee", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees#operation=batch-create",
    validator: validate_BatchCreateAttendee_611339, base: "/",
    url: url_BatchCreateAttendee_611340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateRoomMembership_611356 = ref object of OpenApiRestCall_610658
proc url_BatchCreateRoomMembership_611358(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchCreateRoomMembership_611357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds up to 50 members to a chat room in an Amazon Chime Enterprise account. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
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
  var valid_611359 = path.getOrDefault("accountId")
  valid_611359 = validateParameter(valid_611359, JString, required = true,
                                 default = nil)
  if valid_611359 != nil:
    section.add "accountId", valid_611359
  var valid_611360 = path.getOrDefault("roomId")
  valid_611360 = validateParameter(valid_611360, JString, required = true,
                                 default = nil)
  if valid_611360 != nil:
    section.add "roomId", valid_611360
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611361 = query.getOrDefault("operation")
  valid_611361 = validateParameter(valid_611361, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_611361 != nil:
    section.add "operation", valid_611361
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
  var valid_611362 = header.getOrDefault("X-Amz-Signature")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Signature", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Content-Sha256", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Date")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Date", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Credential")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Credential", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Security-Token")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Security-Token", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Algorithm")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Algorithm", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-SignedHeaders", valid_611368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611370: Call_BatchCreateRoomMembership_611356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds up to 50 members to a chat room in an Amazon Chime Enterprise account. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_611370.validator(path, query, header, formData, body)
  let scheme = call_611370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611370.url(scheme.get, call_611370.host, call_611370.base,
                         call_611370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611370, url, valid)

proc call*(call_611371: Call_BatchCreateRoomMembership_611356; body: JsonNode;
          accountId: string; roomId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateRoomMembership
  ## Adds up to 50 members to a chat room in an Amazon Chime Enterprise account. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_611372 = newJObject()
  var query_611373 = newJObject()
  var body_611374 = newJObject()
  add(query_611373, "operation", newJString(operation))
  if body != nil:
    body_611374 = body
  add(path_611372, "accountId", newJString(accountId))
  add(path_611372, "roomId", newJString(roomId))
  result = call_611371.call(path_611372, query_611373, nil, nil, body_611374)

var batchCreateRoomMembership* = Call_BatchCreateRoomMembership_611356(
    name: "batchCreateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}/memberships#operation=batch-create",
    validator: validate_BatchCreateRoomMembership_611357, base: "/",
    url: url_BatchCreateRoomMembership_611358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_611375 = ref object of OpenApiRestCall_610658
proc url_BatchDeletePhoneNumber_611377(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeletePhoneNumber_611376(path: JsonNode; query: JsonNode;
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
  var valid_611378 = query.getOrDefault("operation")
  valid_611378 = validateParameter(valid_611378, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_611378 != nil:
    section.add "operation", valid_611378
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
  var valid_611379 = header.getOrDefault("X-Amz-Signature")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Signature", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Content-Sha256", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Date")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Date", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Credential")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Credential", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Security-Token")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Security-Token", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Algorithm")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Algorithm", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-SignedHeaders", valid_611385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611387: Call_BatchDeletePhoneNumber_611375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_611387.validator(path, query, header, formData, body)
  let scheme = call_611387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611387.url(scheme.get, call_611387.host, call_611387.base,
                         call_611387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611387, url, valid)

proc call*(call_611388: Call_BatchDeletePhoneNumber_611375; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_611389 = newJObject()
  var body_611390 = newJObject()
  add(query_611389, "operation", newJString(operation))
  if body != nil:
    body_611390 = body
  result = call_611388.call(nil, query_611389, nil, nil, body_611390)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_611375(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_611376, base: "/",
    url: url_BatchDeletePhoneNumber_611377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_611391 = ref object of OpenApiRestCall_610658
proc url_BatchSuspendUser_611393(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchSuspendUser_611392(path: JsonNode; query: JsonNode;
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
  var valid_611394 = path.getOrDefault("accountId")
  valid_611394 = validateParameter(valid_611394, JString, required = true,
                                 default = nil)
  if valid_611394 != nil:
    section.add "accountId", valid_611394
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611395 = query.getOrDefault("operation")
  valid_611395 = validateParameter(valid_611395, JString, required = true,
                                 default = newJString("suspend"))
  if valid_611395 != nil:
    section.add "operation", valid_611395
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
  var valid_611396 = header.getOrDefault("X-Amz-Signature")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Signature", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Content-Sha256", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Date")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Date", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Credential")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Credential", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Security-Token")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Security-Token", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Algorithm")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Algorithm", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-SignedHeaders", valid_611402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611404: Call_BatchSuspendUser_611391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_611404.validator(path, query, header, formData, body)
  let scheme = call_611404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611404.url(scheme.get, call_611404.host, call_611404.base,
                         call_611404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611404, url, valid)

proc call*(call_611405: Call_BatchSuspendUser_611391; body: JsonNode;
          accountId: string; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611406 = newJObject()
  var query_611407 = newJObject()
  var body_611408 = newJObject()
  add(query_611407, "operation", newJString(operation))
  if body != nil:
    body_611408 = body
  add(path_611406, "accountId", newJString(accountId))
  result = call_611405.call(path_611406, query_611407, nil, nil, body_611408)

var batchSuspendUser* = Call_BatchSuspendUser_611391(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_611392, base: "/",
    url: url_BatchSuspendUser_611393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_611409 = ref object of OpenApiRestCall_610658
proc url_BatchUnsuspendUser_611411(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchUnsuspendUser_611410(path: JsonNode; query: JsonNode;
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
  var valid_611412 = path.getOrDefault("accountId")
  valid_611412 = validateParameter(valid_611412, JString, required = true,
                                 default = nil)
  if valid_611412 != nil:
    section.add "accountId", valid_611412
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611413 = query.getOrDefault("operation")
  valid_611413 = validateParameter(valid_611413, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_611413 != nil:
    section.add "operation", valid_611413
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
  var valid_611414 = header.getOrDefault("X-Amz-Signature")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Signature", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Content-Sha256", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Date")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Date", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Credential")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Credential", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Security-Token")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Security-Token", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Algorithm")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Algorithm", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-SignedHeaders", valid_611420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611422: Call_BatchUnsuspendUser_611409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_611422.validator(path, query, header, formData, body)
  let scheme = call_611422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611422.url(scheme.get, call_611422.host, call_611422.base,
                         call_611422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611422, url, valid)

proc call*(call_611423: Call_BatchUnsuspendUser_611409; body: JsonNode;
          accountId: string; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611424 = newJObject()
  var query_611425 = newJObject()
  var body_611426 = newJObject()
  add(query_611425, "operation", newJString(operation))
  if body != nil:
    body_611426 = body
  add(path_611424, "accountId", newJString(accountId))
  result = call_611423.call(path_611424, query_611425, nil, nil, body_611426)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_611409(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_611410, base: "/",
    url: url_BatchUnsuspendUser_611411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_611427 = ref object of OpenApiRestCall_610658
proc url_BatchUpdatePhoneNumber_611429(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchUpdatePhoneNumber_611428(path: JsonNode; query: JsonNode;
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
  var valid_611430 = query.getOrDefault("operation")
  valid_611430 = validateParameter(valid_611430, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_611430 != nil:
    section.add "operation", valid_611430
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
  var valid_611431 = header.getOrDefault("X-Amz-Signature")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Signature", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Content-Sha256", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Date")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Date", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Credential")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Credential", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Security-Token")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Security-Token", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Algorithm")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Algorithm", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-SignedHeaders", valid_611437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611439: Call_BatchUpdatePhoneNumber_611427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_611439.validator(path, query, header, formData, body)
  let scheme = call_611439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611439.url(scheme.get, call_611439.host, call_611439.base,
                         call_611439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611439, url, valid)

proc call*(call_611440: Call_BatchUpdatePhoneNumber_611427; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_611441 = newJObject()
  var body_611442 = newJObject()
  add(query_611441, "operation", newJString(operation))
  if body != nil:
    body_611442 = body
  result = call_611440.call(nil, query_611441, nil, nil, body_611442)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_611427(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_611428, base: "/",
    url: url_BatchUpdatePhoneNumber_611429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_611464 = ref object of OpenApiRestCall_610658
proc url_BatchUpdateUser_611466(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchUpdateUser_611465(path: JsonNode; query: JsonNode;
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
  var valid_611467 = path.getOrDefault("accountId")
  valid_611467 = validateParameter(valid_611467, JString, required = true,
                                 default = nil)
  if valid_611467 != nil:
    section.add "accountId", valid_611467
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
  var valid_611468 = header.getOrDefault("X-Amz-Signature")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Signature", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Content-Sha256", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Date")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Date", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Credential")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Credential", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Security-Token")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Security-Token", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Algorithm")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Algorithm", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-SignedHeaders", valid_611474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611476: Call_BatchUpdateUser_611464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_611476.validator(path, query, header, formData, body)
  let scheme = call_611476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611476.url(scheme.get, call_611476.host, call_611476.base,
                         call_611476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611476, url, valid)

proc call*(call_611477: Call_BatchUpdateUser_611464; body: JsonNode;
          accountId: string): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611478 = newJObject()
  var body_611479 = newJObject()
  if body != nil:
    body_611479 = body
  add(path_611478, "accountId", newJString(accountId))
  result = call_611477.call(path_611478, nil, nil, nil, body_611479)

var batchUpdateUser* = Call_BatchUpdateUser_611464(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_611465,
    base: "/", url: url_BatchUpdateUser_611466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_611443 = ref object of OpenApiRestCall_610658
proc url_ListUsers_611445(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_611444(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611446 = path.getOrDefault("accountId")
  valid_611446 = validateParameter(valid_611446, JString, required = true,
                                 default = nil)
  if valid_611446 != nil:
    section.add "accountId", valid_611446
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
  var valid_611447 = query.getOrDefault("MaxResults")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "MaxResults", valid_611447
  var valid_611448 = query.getOrDefault("user-email")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "user-email", valid_611448
  var valid_611449 = query.getOrDefault("NextToken")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "NextToken", valid_611449
  var valid_611450 = query.getOrDefault("user-type")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = newJString("PrivateUser"))
  if valid_611450 != nil:
    section.add "user-type", valid_611450
  var valid_611451 = query.getOrDefault("max-results")
  valid_611451 = validateParameter(valid_611451, JInt, required = false, default = nil)
  if valid_611451 != nil:
    section.add "max-results", valid_611451
  var valid_611452 = query.getOrDefault("next-token")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "next-token", valid_611452
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
  var valid_611453 = header.getOrDefault("X-Amz-Signature")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Signature", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Content-Sha256", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Date")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Date", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Credential")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Credential", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Security-Token")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Security-Token", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Algorithm")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Algorithm", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-SignedHeaders", valid_611459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611460: Call_ListUsers_611443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_611460.validator(path, query, header, formData, body)
  let scheme = call_611460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611460.url(scheme.get, call_611460.host, call_611460.base,
                         call_611460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611460, url, valid)

proc call*(call_611461: Call_ListUsers_611443; accountId: string;
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
  var path_611462 = newJObject()
  var query_611463 = newJObject()
  add(query_611463, "MaxResults", newJString(MaxResults))
  add(query_611463, "user-email", newJString(userEmail))
  add(query_611463, "NextToken", newJString(NextToken))
  add(query_611463, "user-type", newJString(userType))
  add(query_611463, "max-results", newJInt(maxResults))
  add(path_611462, "accountId", newJString(accountId))
  add(query_611463, "next-token", newJString(nextToken))
  result = call_611461.call(path_611462, query_611463, nil, nil, nil)

var listUsers* = Call_ListUsers_611443(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_611444,
                                    base: "/", url: url_ListUsers_611445,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_611499 = ref object of OpenApiRestCall_610658
proc url_CreateAccount_611501(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAccount_611500(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611502 = header.getOrDefault("X-Amz-Signature")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Signature", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Content-Sha256", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Date")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Date", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Credential")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Credential", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Security-Token")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Security-Token", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Algorithm")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Algorithm", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-SignedHeaders", valid_611508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611510: Call_CreateAccount_611499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_611510.validator(path, query, header, formData, body)
  let scheme = call_611510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611510.url(scheme.get, call_611510.host, call_611510.base,
                         call_611510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611510, url, valid)

proc call*(call_611511: Call_CreateAccount_611499; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_611512 = newJObject()
  if body != nil:
    body_611512 = body
  result = call_611511.call(nil, nil, nil, nil, body_611512)

var createAccount* = Call_CreateAccount_611499(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_611500, base: "/", url: url_CreateAccount_611501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_611480 = ref object of OpenApiRestCall_610658
proc url_ListAccounts_611482(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_611481(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611483 = query.getOrDefault("name")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "name", valid_611483
  var valid_611484 = query.getOrDefault("MaxResults")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "MaxResults", valid_611484
  var valid_611485 = query.getOrDefault("user-email")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "user-email", valid_611485
  var valid_611486 = query.getOrDefault("NextToken")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "NextToken", valid_611486
  var valid_611487 = query.getOrDefault("max-results")
  valid_611487 = validateParameter(valid_611487, JInt, required = false, default = nil)
  if valid_611487 != nil:
    section.add "max-results", valid_611487
  var valid_611488 = query.getOrDefault("next-token")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "next-token", valid_611488
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
  var valid_611489 = header.getOrDefault("X-Amz-Signature")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Signature", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Content-Sha256", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Date")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Date", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Credential")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Credential", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Security-Token")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Security-Token", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Algorithm")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Algorithm", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-SignedHeaders", valid_611495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611496: Call_ListAccounts_611480; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_611496.validator(path, query, header, formData, body)
  let scheme = call_611496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611496.url(scheme.get, call_611496.host, call_611496.base,
                         call_611496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611496, url, valid)

proc call*(call_611497: Call_ListAccounts_611480; name: string = "";
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
  var query_611498 = newJObject()
  add(query_611498, "name", newJString(name))
  add(query_611498, "MaxResults", newJString(MaxResults))
  add(query_611498, "user-email", newJString(userEmail))
  add(query_611498, "NextToken", newJString(NextToken))
  add(query_611498, "max-results", newJInt(maxResults))
  add(query_611498, "next-token", newJString(nextToken))
  result = call_611497.call(nil, query_611498, nil, nil, nil)

var listAccounts* = Call_ListAccounts_611480(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_611481, base: "/", url: url_ListAccounts_611482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAttendee_611532 = ref object of OpenApiRestCall_610658
proc url_CreateAttendee_611534(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAttendee_611533(path: JsonNode; query: JsonNode;
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
  var valid_611535 = path.getOrDefault("meetingId")
  valid_611535 = validateParameter(valid_611535, JString, required = true,
                                 default = nil)
  if valid_611535 != nil:
    section.add "meetingId", valid_611535
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
  var valid_611536 = header.getOrDefault("X-Amz-Signature")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Signature", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Content-Sha256", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Date")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Date", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Credential")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Credential", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Security-Token")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Security-Token", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Algorithm")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Algorithm", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-SignedHeaders", valid_611542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611544: Call_CreateAttendee_611532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611544.validator(path, query, header, formData, body)
  let scheme = call_611544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611544.url(scheme.get, call_611544.host, call_611544.base,
                         call_611544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611544, url, valid)

proc call*(call_611545: Call_CreateAttendee_611532; body: JsonNode; meetingId: string): Recallable =
  ## createAttendee
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_611546 = newJObject()
  var body_611547 = newJObject()
  if body != nil:
    body_611547 = body
  add(path_611546, "meetingId", newJString(meetingId))
  result = call_611545.call(path_611546, nil, nil, nil, body_611547)

var createAttendee* = Call_CreateAttendee_611532(name: "createAttendee",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_CreateAttendee_611533,
    base: "/", url: url_CreateAttendee_611534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttendees_611513 = ref object of OpenApiRestCall_610658
proc url_ListAttendees_611515(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListAttendees_611514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611516 = path.getOrDefault("meetingId")
  valid_611516 = validateParameter(valid_611516, JString, required = true,
                                 default = nil)
  if valid_611516 != nil:
    section.add "meetingId", valid_611516
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
  var valid_611517 = query.getOrDefault("MaxResults")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "MaxResults", valid_611517
  var valid_611518 = query.getOrDefault("NextToken")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "NextToken", valid_611518
  var valid_611519 = query.getOrDefault("max-results")
  valid_611519 = validateParameter(valid_611519, JInt, required = false, default = nil)
  if valid_611519 != nil:
    section.add "max-results", valid_611519
  var valid_611520 = query.getOrDefault("next-token")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "next-token", valid_611520
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
  var valid_611521 = header.getOrDefault("X-Amz-Signature")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Signature", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Content-Sha256", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Date")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Date", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Credential")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Credential", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Security-Token")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Security-Token", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Algorithm")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Algorithm", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-SignedHeaders", valid_611527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611528: Call_ListAttendees_611513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611528.validator(path, query, header, formData, body)
  let scheme = call_611528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611528.url(scheme.get, call_611528.host, call_611528.base,
                         call_611528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611528, url, valid)

proc call*(call_611529: Call_ListAttendees_611513; meetingId: string;
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
  var path_611530 = newJObject()
  var query_611531 = newJObject()
  add(query_611531, "MaxResults", newJString(MaxResults))
  add(query_611531, "NextToken", newJString(NextToken))
  add(query_611531, "max-results", newJInt(maxResults))
  add(path_611530, "meetingId", newJString(meetingId))
  add(query_611531, "next-token", newJString(nextToken))
  result = call_611529.call(path_611530, query_611531, nil, nil, nil)

var listAttendees* = Call_ListAttendees_611513(name: "listAttendees",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_ListAttendees_611514,
    base: "/", url: url_ListAttendees_611515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_611567 = ref object of OpenApiRestCall_610658
proc url_CreateBot_611569(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBot_611568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611570 = path.getOrDefault("accountId")
  valid_611570 = validateParameter(valid_611570, JString, required = true,
                                 default = nil)
  if valid_611570 != nil:
    section.add "accountId", valid_611570
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
  var valid_611571 = header.getOrDefault("X-Amz-Signature")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Signature", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Content-Sha256", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Date")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Date", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Credential")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Credential", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Security-Token")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Security-Token", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Algorithm")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Algorithm", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-SignedHeaders", valid_611577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611579: Call_CreateBot_611567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_611579.validator(path, query, header, formData, body)
  let scheme = call_611579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611579.url(scheme.get, call_611579.host, call_611579.base,
                         call_611579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611579, url, valid)

proc call*(call_611580: Call_CreateBot_611567; body: JsonNode; accountId: string): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611581 = newJObject()
  var body_611582 = newJObject()
  if body != nil:
    body_611582 = body
  add(path_611581, "accountId", newJString(accountId))
  result = call_611580.call(path_611581, nil, nil, nil, body_611582)

var createBot* = Call_CreateBot_611567(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_611568,
                                    base: "/", url: url_CreateBot_611569,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_611548 = ref object of OpenApiRestCall_610658
proc url_ListBots_611550(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBots_611549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611551 = path.getOrDefault("accountId")
  valid_611551 = validateParameter(valid_611551, JString, required = true,
                                 default = nil)
  if valid_611551 != nil:
    section.add "accountId", valid_611551
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
  var valid_611552 = query.getOrDefault("MaxResults")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "MaxResults", valid_611552
  var valid_611553 = query.getOrDefault("NextToken")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "NextToken", valid_611553
  var valid_611554 = query.getOrDefault("max-results")
  valid_611554 = validateParameter(valid_611554, JInt, required = false, default = nil)
  if valid_611554 != nil:
    section.add "max-results", valid_611554
  var valid_611555 = query.getOrDefault("next-token")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "next-token", valid_611555
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
  var valid_611556 = header.getOrDefault("X-Amz-Signature")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Signature", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Content-Sha256", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Date")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Date", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Credential")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Credential", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Security-Token")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Security-Token", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Algorithm")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Algorithm", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-SignedHeaders", valid_611562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611563: Call_ListBots_611548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_611563.validator(path, query, header, formData, body)
  let scheme = call_611563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611563.url(scheme.get, call_611563.host, call_611563.base,
                         call_611563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611563, url, valid)

proc call*(call_611564: Call_ListBots_611548; accountId: string;
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
  var path_611565 = newJObject()
  var query_611566 = newJObject()
  add(query_611566, "MaxResults", newJString(MaxResults))
  add(query_611566, "NextToken", newJString(NextToken))
  add(query_611566, "max-results", newJInt(maxResults))
  add(path_611565, "accountId", newJString(accountId))
  add(query_611566, "next-token", newJString(nextToken))
  result = call_611564.call(path_611565, query_611566, nil, nil, nil)

var listBots* = Call_ListBots_611548(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_611549, base: "/",
                                  url: url_ListBots_611550,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMeeting_611600 = ref object of OpenApiRestCall_610658
proc url_CreateMeeting_611602(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMeeting_611601(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611603 = header.getOrDefault("X-Amz-Signature")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Signature", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Content-Sha256", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Date")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Date", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Credential")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Credential", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Security-Token")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Security-Token", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Algorithm")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Algorithm", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-SignedHeaders", valid_611609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611611: Call_CreateMeeting_611600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611611.validator(path, query, header, formData, body)
  let scheme = call_611611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611611.url(scheme.get, call_611611.host, call_611611.base,
                         call_611611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611611, url, valid)

proc call*(call_611612: Call_CreateMeeting_611600; body: JsonNode): Recallable =
  ## createMeeting
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  var body_611613 = newJObject()
  if body != nil:
    body_611613 = body
  result = call_611612.call(nil, nil, nil, nil, body_611613)

var createMeeting* = Call_CreateMeeting_611600(name: "createMeeting",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_CreateMeeting_611601, base: "/", url: url_CreateMeeting_611602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeetings_611583 = ref object of OpenApiRestCall_610658
proc url_ListMeetings_611585(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeetings_611584(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611586 = query.getOrDefault("MaxResults")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "MaxResults", valid_611586
  var valid_611587 = query.getOrDefault("NextToken")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "NextToken", valid_611587
  var valid_611588 = query.getOrDefault("max-results")
  valid_611588 = validateParameter(valid_611588, JInt, required = false, default = nil)
  if valid_611588 != nil:
    section.add "max-results", valid_611588
  var valid_611589 = query.getOrDefault("next-token")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "next-token", valid_611589
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
  var valid_611590 = header.getOrDefault("X-Amz-Signature")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Signature", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Content-Sha256", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Date")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Date", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Credential")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Credential", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Security-Token")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Security-Token", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Algorithm")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Algorithm", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-SignedHeaders", valid_611596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611597: Call_ListMeetings_611583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611597.validator(path, query, header, formData, body)
  let scheme = call_611597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611597.url(scheme.get, call_611597.host, call_611597.base,
                         call_611597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611597, url, valid)

proc call*(call_611598: Call_ListMeetings_611583; MaxResults: string = "";
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
  var query_611599 = newJObject()
  add(query_611599, "MaxResults", newJString(MaxResults))
  add(query_611599, "NextToken", newJString(NextToken))
  add(query_611599, "max-results", newJInt(maxResults))
  add(query_611599, "next-token", newJString(nextToken))
  result = call_611598.call(nil, query_611599, nil, nil, nil)

var listMeetings* = Call_ListMeetings_611583(name: "listMeetings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_ListMeetings_611584, base: "/", url: url_ListMeetings_611585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_611631 = ref object of OpenApiRestCall_610658
proc url_CreatePhoneNumberOrder_611633(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePhoneNumberOrder_611632(path: JsonNode; query: JsonNode;
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
  var valid_611634 = header.getOrDefault("X-Amz-Signature")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Signature", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Content-Sha256", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Date")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Date", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Credential")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Credential", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Security-Token")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Security-Token", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Algorithm")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Algorithm", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-SignedHeaders", valid_611640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611642: Call_CreatePhoneNumberOrder_611631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_611642.validator(path, query, header, formData, body)
  let scheme = call_611642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611642.url(scheme.get, call_611642.host, call_611642.base,
                         call_611642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611642, url, valid)

proc call*(call_611643: Call_CreatePhoneNumberOrder_611631; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_611644 = newJObject()
  if body != nil:
    body_611644 = body
  result = call_611643.call(nil, nil, nil, nil, body_611644)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_611631(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_611632, base: "/",
    url: url_CreatePhoneNumberOrder_611633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_611614 = ref object of OpenApiRestCall_610658
proc url_ListPhoneNumberOrders_611616(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumberOrders_611615(path: JsonNode; query: JsonNode;
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
  var valid_611617 = query.getOrDefault("MaxResults")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "MaxResults", valid_611617
  var valid_611618 = query.getOrDefault("NextToken")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "NextToken", valid_611618
  var valid_611619 = query.getOrDefault("max-results")
  valid_611619 = validateParameter(valid_611619, JInt, required = false, default = nil)
  if valid_611619 != nil:
    section.add "max-results", valid_611619
  var valid_611620 = query.getOrDefault("next-token")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "next-token", valid_611620
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
  var valid_611621 = header.getOrDefault("X-Amz-Signature")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Signature", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Content-Sha256", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Date")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Date", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Credential")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Credential", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Security-Token")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Security-Token", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Algorithm")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Algorithm", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-SignedHeaders", valid_611627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611628: Call_ListPhoneNumberOrders_611614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_611628.validator(path, query, header, formData, body)
  let scheme = call_611628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611628.url(scheme.get, call_611628.host, call_611628.base,
                         call_611628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611628, url, valid)

proc call*(call_611629: Call_ListPhoneNumberOrders_611614; MaxResults: string = "";
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
  var query_611630 = newJObject()
  add(query_611630, "MaxResults", newJString(MaxResults))
  add(query_611630, "NextToken", newJString(NextToken))
  add(query_611630, "max-results", newJInt(maxResults))
  add(query_611630, "next-token", newJString(nextToken))
  result = call_611629.call(nil, query_611630, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_611614(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_611615, base: "/",
    url: url_ListPhoneNumberOrders_611616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_611665 = ref object of OpenApiRestCall_610658
proc url_CreateRoom_611667(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoom_611666(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a chat room for the specified Amazon Chime Enterprise account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_611668 = path.getOrDefault("accountId")
  valid_611668 = validateParameter(valid_611668, JString, required = true,
                                 default = nil)
  if valid_611668 != nil:
    section.add "accountId", valid_611668
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
  var valid_611669 = header.getOrDefault("X-Amz-Signature")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Signature", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Content-Sha256", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Date")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Date", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Credential")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Credential", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-Security-Token")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-Security-Token", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Algorithm")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Algorithm", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-SignedHeaders", valid_611675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611677: Call_CreateRoom_611665; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a chat room for the specified Amazon Chime Enterprise account.
  ## 
  let valid = call_611677.validator(path, query, header, formData, body)
  let scheme = call_611677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611677.url(scheme.get, call_611677.host, call_611677.base,
                         call_611677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611677, url, valid)

proc call*(call_611678: Call_CreateRoom_611665; body: JsonNode; accountId: string): Recallable =
  ## createRoom
  ## Creates a chat room for the specified Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611679 = newJObject()
  var body_611680 = newJObject()
  if body != nil:
    body_611680 = body
  add(path_611679, "accountId", newJString(accountId))
  result = call_611678.call(path_611679, nil, nil, nil, body_611680)

var createRoom* = Call_CreateRoom_611665(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/rooms",
                                      validator: validate_CreateRoom_611666,
                                      base: "/", url: url_CreateRoom_611667,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRooms_611645 = ref object of OpenApiRestCall_610658
proc url_ListRooms_611647(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRooms_611646(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_611648 = path.getOrDefault("accountId")
  valid_611648 = validateParameter(valid_611648, JString, required = true,
                                 default = nil)
  if valid_611648 != nil:
    section.add "accountId", valid_611648
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
  var valid_611649 = query.getOrDefault("member-id")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "member-id", valid_611649
  var valid_611650 = query.getOrDefault("MaxResults")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "MaxResults", valid_611650
  var valid_611651 = query.getOrDefault("NextToken")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "NextToken", valid_611651
  var valid_611652 = query.getOrDefault("max-results")
  valid_611652 = validateParameter(valid_611652, JInt, required = false, default = nil)
  if valid_611652 != nil:
    section.add "max-results", valid_611652
  var valid_611653 = query.getOrDefault("next-token")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "next-token", valid_611653
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
  var valid_611654 = header.getOrDefault("X-Amz-Signature")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Signature", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Content-Sha256", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Date")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Date", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Credential")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Credential", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Security-Token")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Security-Token", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Algorithm")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Algorithm", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-SignedHeaders", valid_611660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611661: Call_ListRooms_611645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  let valid = call_611661.validator(path, query, header, formData, body)
  let scheme = call_611661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611661.url(scheme.get, call_611661.host, call_611661.base,
                         call_611661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611661, url, valid)

proc call*(call_611662: Call_ListRooms_611645; accountId: string;
          memberId: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listRooms
  ## Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
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
  var path_611663 = newJObject()
  var query_611664 = newJObject()
  add(query_611664, "member-id", newJString(memberId))
  add(query_611664, "MaxResults", newJString(MaxResults))
  add(query_611664, "NextToken", newJString(NextToken))
  add(query_611664, "max-results", newJInt(maxResults))
  add(path_611663, "accountId", newJString(accountId))
  add(query_611664, "next-token", newJString(nextToken))
  result = call_611662.call(path_611663, query_611664, nil, nil, nil)

var listRooms* = Call_ListRooms_611645(name: "listRooms", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/rooms",
                                    validator: validate_ListRooms_611646,
                                    base: "/", url: url_ListRooms_611647,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoomMembership_611701 = ref object of OpenApiRestCall_610658
proc url_CreateRoomMembership_611703(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoomMembership_611702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a member to a chat room in an Amazon Chime Enterprise account. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
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
  var valid_611704 = path.getOrDefault("accountId")
  valid_611704 = validateParameter(valid_611704, JString, required = true,
                                 default = nil)
  if valid_611704 != nil:
    section.add "accountId", valid_611704
  var valid_611705 = path.getOrDefault("roomId")
  valid_611705 = validateParameter(valid_611705, JString, required = true,
                                 default = nil)
  if valid_611705 != nil:
    section.add "roomId", valid_611705
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
  var valid_611706 = header.getOrDefault("X-Amz-Signature")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Signature", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Content-Sha256", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Date")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Date", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Credential")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Credential", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Security-Token")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Security-Token", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Algorithm")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Algorithm", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-SignedHeaders", valid_611712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611714: Call_CreateRoomMembership_611701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a member to a chat room in an Amazon Chime Enterprise account. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_611714.validator(path, query, header, formData, body)
  let scheme = call_611714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611714.url(scheme.get, call_611714.host, call_611714.base,
                         call_611714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611714, url, valid)

proc call*(call_611715: Call_CreateRoomMembership_611701; body: JsonNode;
          accountId: string; roomId: string): Recallable =
  ## createRoomMembership
  ## Adds a member to a chat room in an Amazon Chime Enterprise account. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_611716 = newJObject()
  var body_611717 = newJObject()
  if body != nil:
    body_611717 = body
  add(path_611716, "accountId", newJString(accountId))
  add(path_611716, "roomId", newJString(roomId))
  result = call_611715.call(path_611716, nil, nil, nil, body_611717)

var createRoomMembership* = Call_CreateRoomMembership_611701(
    name: "createRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_CreateRoomMembership_611702, base: "/",
    url: url_CreateRoomMembership_611703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoomMemberships_611681 = ref object of OpenApiRestCall_610658
proc url_ListRoomMemberships_611683(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRoomMemberships_611682(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the membership details for the specified room in an Amazon Chime Enterprise account, such as the members' IDs, email addresses, and names.
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
  var valid_611684 = path.getOrDefault("accountId")
  valid_611684 = validateParameter(valid_611684, JString, required = true,
                                 default = nil)
  if valid_611684 != nil:
    section.add "accountId", valid_611684
  var valid_611685 = path.getOrDefault("roomId")
  valid_611685 = validateParameter(valid_611685, JString, required = true,
                                 default = nil)
  if valid_611685 != nil:
    section.add "roomId", valid_611685
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
  var valid_611686 = query.getOrDefault("MaxResults")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "MaxResults", valid_611686
  var valid_611687 = query.getOrDefault("NextToken")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "NextToken", valid_611687
  var valid_611688 = query.getOrDefault("max-results")
  valid_611688 = validateParameter(valid_611688, JInt, required = false, default = nil)
  if valid_611688 != nil:
    section.add "max-results", valid_611688
  var valid_611689 = query.getOrDefault("next-token")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "next-token", valid_611689
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
  var valid_611690 = header.getOrDefault("X-Amz-Signature")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Signature", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Content-Sha256", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Date")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Date", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Credential")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Credential", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Security-Token")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Security-Token", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Algorithm")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Algorithm", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-SignedHeaders", valid_611696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611697: Call_ListRoomMemberships_611681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the membership details for the specified room in an Amazon Chime Enterprise account, such as the members' IDs, email addresses, and names.
  ## 
  let valid = call_611697.validator(path, query, header, formData, body)
  let scheme = call_611697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611697.url(scheme.get, call_611697.host, call_611697.base,
                         call_611697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611697, url, valid)

proc call*(call_611698: Call_ListRoomMemberships_611681; accountId: string;
          roomId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listRoomMemberships
  ## Lists the membership details for the specified room in an Amazon Chime Enterprise account, such as the members' IDs, email addresses, and names.
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
  var path_611699 = newJObject()
  var query_611700 = newJObject()
  add(query_611700, "MaxResults", newJString(MaxResults))
  add(query_611700, "NextToken", newJString(NextToken))
  add(query_611700, "max-results", newJInt(maxResults))
  add(path_611699, "accountId", newJString(accountId))
  add(path_611699, "roomId", newJString(roomId))
  add(query_611700, "next-token", newJString(nextToken))
  result = call_611698.call(path_611699, query_611700, nil, nil, nil)

var listRoomMemberships* = Call_ListRoomMemberships_611681(
    name: "listRoomMemberships", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_ListRoomMemberships_611682, base: "/",
    url: url_ListRoomMemberships_611683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_611718 = ref object of OpenApiRestCall_610658
proc url_CreateUser_611720(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUser_611719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611721 = path.getOrDefault("accountId")
  valid_611721 = validateParameter(valid_611721, JString, required = true,
                                 default = nil)
  if valid_611721 != nil:
    section.add "accountId", valid_611721
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_611722 = query.getOrDefault("operation")
  valid_611722 = validateParameter(valid_611722, JString, required = true,
                                 default = newJString("create"))
  if valid_611722 != nil:
    section.add "operation", valid_611722
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
  var valid_611723 = header.getOrDefault("X-Amz-Signature")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Signature", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Content-Sha256", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Date")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Date", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Credential")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Credential", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Security-Token")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Security-Token", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Algorithm")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Algorithm", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-SignedHeaders", valid_611729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611731: Call_CreateUser_611718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user under the specified Amazon Chime account.
  ## 
  let valid = call_611731.validator(path, query, header, formData, body)
  let scheme = call_611731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611731.url(scheme.get, call_611731.host, call_611731.base,
                         call_611731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611731, url, valid)

proc call*(call_611732: Call_CreateUser_611718; body: JsonNode; accountId: string;
          operation: string = "create"): Recallable =
  ## createUser
  ## Creates a user under the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611733 = newJObject()
  var query_611734 = newJObject()
  var body_611735 = newJObject()
  add(query_611734, "operation", newJString(operation))
  if body != nil:
    body_611735 = body
  add(path_611733, "accountId", newJString(accountId))
  result = call_611732.call(path_611733, query_611734, nil, nil, body_611735)

var createUser* = Call_CreateUser_611718(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=create",
                                      validator: validate_CreateUser_611719,
                                      base: "/", url: url_CreateUser_611720,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_611753 = ref object of OpenApiRestCall_610658
proc url_CreateVoiceConnector_611755(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnector_611754(path: JsonNode; query: JsonNode;
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
  var valid_611756 = header.getOrDefault("X-Amz-Signature")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Signature", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Content-Sha256", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Date")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Date", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Credential")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Credential", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Security-Token")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Security-Token", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Algorithm")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Algorithm", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-SignedHeaders", valid_611762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611764: Call_CreateVoiceConnector_611753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  let valid = call_611764.validator(path, query, header, formData, body)
  let scheme = call_611764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611764.url(scheme.get, call_611764.host, call_611764.base,
                         call_611764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611764, url, valid)

proc call*(call_611765: Call_CreateVoiceConnector_611753; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ##   body: JObject (required)
  var body_611766 = newJObject()
  if body != nil:
    body_611766 = body
  result = call_611765.call(nil, nil, nil, nil, body_611766)

var createVoiceConnector* = Call_CreateVoiceConnector_611753(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_611754, base: "/",
    url: url_CreateVoiceConnector_611755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_611736 = ref object of OpenApiRestCall_610658
proc url_ListVoiceConnectors_611738(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectors_611737(path: JsonNode; query: JsonNode;
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
  var valid_611739 = query.getOrDefault("MaxResults")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "MaxResults", valid_611739
  var valid_611740 = query.getOrDefault("NextToken")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "NextToken", valid_611740
  var valid_611741 = query.getOrDefault("max-results")
  valid_611741 = validateParameter(valid_611741, JInt, required = false, default = nil)
  if valid_611741 != nil:
    section.add "max-results", valid_611741
  var valid_611742 = query.getOrDefault("next-token")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "next-token", valid_611742
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
  var valid_611743 = header.getOrDefault("X-Amz-Signature")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Signature", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Content-Sha256", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Date")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Date", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Credential")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Credential", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Security-Token")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Security-Token", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Algorithm")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Algorithm", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-SignedHeaders", valid_611749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611750: Call_ListVoiceConnectors_611736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_611750.validator(path, query, header, formData, body)
  let scheme = call_611750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611750.url(scheme.get, call_611750.host, call_611750.base,
                         call_611750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611750, url, valid)

proc call*(call_611751: Call_ListVoiceConnectors_611736; MaxResults: string = "";
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
  var query_611752 = newJObject()
  add(query_611752, "MaxResults", newJString(MaxResults))
  add(query_611752, "NextToken", newJString(NextToken))
  add(query_611752, "max-results", newJInt(maxResults))
  add(query_611752, "next-token", newJString(nextToken))
  result = call_611751.call(nil, query_611752, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_611736(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_611737, base: "/",
    url: url_ListVoiceConnectors_611738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnectorGroup_611784 = ref object of OpenApiRestCall_610658
proc url_CreateVoiceConnectorGroup_611786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnectorGroup_611785(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
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
  var valid_611787 = header.getOrDefault("X-Amz-Signature")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Signature", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Content-Sha256", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Date")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Date", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Credential")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Credential", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Security-Token")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Security-Token", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Algorithm")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Algorithm", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-SignedHeaders", valid_611793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611795: Call_CreateVoiceConnectorGroup_611784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  let valid = call_611795.validator(path, query, header, formData, body)
  let scheme = call_611795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611795.url(scheme.get, call_611795.host, call_611795.base,
                         call_611795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611795, url, valid)

proc call*(call_611796: Call_CreateVoiceConnectorGroup_611784; body: JsonNode): Recallable =
  ## createVoiceConnectorGroup
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ##   body: JObject (required)
  var body_611797 = newJObject()
  if body != nil:
    body_611797 = body
  result = call_611796.call(nil, nil, nil, nil, body_611797)

var createVoiceConnectorGroup* = Call_CreateVoiceConnectorGroup_611784(
    name: "createVoiceConnectorGroup", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_CreateVoiceConnectorGroup_611785, base: "/",
    url: url_CreateVoiceConnectorGroup_611786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorGroups_611767 = ref object of OpenApiRestCall_610658
proc url_ListVoiceConnectorGroups_611769(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectorGroups_611768(path: JsonNode; query: JsonNode;
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
  var valid_611770 = query.getOrDefault("MaxResults")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "MaxResults", valid_611770
  var valid_611771 = query.getOrDefault("NextToken")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "NextToken", valid_611771
  var valid_611772 = query.getOrDefault("max-results")
  valid_611772 = validateParameter(valid_611772, JInt, required = false, default = nil)
  if valid_611772 != nil:
    section.add "max-results", valid_611772
  var valid_611773 = query.getOrDefault("next-token")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "next-token", valid_611773
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
  var valid_611774 = header.getOrDefault("X-Amz-Signature")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Signature", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Content-Sha256", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Date")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Date", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Credential")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Credential", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Security-Token")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Security-Token", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Algorithm")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Algorithm", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-SignedHeaders", valid_611780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611781: Call_ListVoiceConnectorGroups_611767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  let valid = call_611781.validator(path, query, header, formData, body)
  let scheme = call_611781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611781.url(scheme.get, call_611781.host, call_611781.base,
                         call_611781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611781, url, valid)

proc call*(call_611782: Call_ListVoiceConnectorGroups_611767;
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
  var query_611783 = newJObject()
  add(query_611783, "MaxResults", newJString(MaxResults))
  add(query_611783, "NextToken", newJString(NextToken))
  add(query_611783, "max-results", newJInt(maxResults))
  add(query_611783, "next-token", newJString(nextToken))
  result = call_611782.call(nil, query_611783, nil, nil, nil)

var listVoiceConnectorGroups* = Call_ListVoiceConnectorGroups_611767(
    name: "listVoiceConnectorGroups", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_ListVoiceConnectorGroups_611768, base: "/",
    url: url_ListVoiceConnectorGroups_611769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_611812 = ref object of OpenApiRestCall_610658
proc url_UpdateAccount_611814(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAccount_611813(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611815 = path.getOrDefault("accountId")
  valid_611815 = validateParameter(valid_611815, JString, required = true,
                                 default = nil)
  if valid_611815 != nil:
    section.add "accountId", valid_611815
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
  var valid_611816 = header.getOrDefault("X-Amz-Signature")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Signature", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Content-Sha256", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Date")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Date", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Credential")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Credential", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-Security-Token")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Security-Token", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Algorithm")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Algorithm", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-SignedHeaders", valid_611822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611824: Call_UpdateAccount_611812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_611824.validator(path, query, header, formData, body)
  let scheme = call_611824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611824.url(scheme.get, call_611824.host, call_611824.base,
                         call_611824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611824, url, valid)

proc call*(call_611825: Call_UpdateAccount_611812; body: JsonNode; accountId: string): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611826 = newJObject()
  var body_611827 = newJObject()
  if body != nil:
    body_611827 = body
  add(path_611826, "accountId", newJString(accountId))
  result = call_611825.call(path_611826, nil, nil, nil, body_611827)

var updateAccount* = Call_UpdateAccount_611812(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_611813,
    base: "/", url: url_UpdateAccount_611814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_611798 = ref object of OpenApiRestCall_610658
proc url_GetAccount_611800(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccount_611799(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611801 = path.getOrDefault("accountId")
  valid_611801 = validateParameter(valid_611801, JString, required = true,
                                 default = nil)
  if valid_611801 != nil:
    section.add "accountId", valid_611801
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
  var valid_611802 = header.getOrDefault("X-Amz-Signature")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Signature", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Content-Sha256", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Date")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Date", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Credential")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Credential", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Security-Token")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Security-Token", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-Algorithm")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Algorithm", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-SignedHeaders", valid_611808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611809: Call_GetAccount_611798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_611809.validator(path, query, header, formData, body)
  let scheme = call_611809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611809.url(scheme.get, call_611809.host, call_611809.base,
                         call_611809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611809, url, valid)

proc call*(call_611810: Call_GetAccount_611798; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611811 = newJObject()
  add(path_611811, "accountId", newJString(accountId))
  result = call_611810.call(path_611811, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_611798(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_611799,
                                      base: "/", url: url_GetAccount_611800,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_611828 = ref object of OpenApiRestCall_610658
proc url_DeleteAccount_611830(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccount_611829(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611831 = path.getOrDefault("accountId")
  valid_611831 = validateParameter(valid_611831, JString, required = true,
                                 default = nil)
  if valid_611831 != nil:
    section.add "accountId", valid_611831
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
  var valid_611832 = header.getOrDefault("X-Amz-Signature")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Signature", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Content-Sha256", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Date")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Date", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Credential")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Credential", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Security-Token")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Security-Token", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-Algorithm")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Algorithm", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-SignedHeaders", valid_611838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611839: Call_DeleteAccount_611828; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_611839.validator(path, query, header, formData, body)
  let scheme = call_611839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611839.url(scheme.get, call_611839.host, call_611839.base,
                         call_611839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611839, url, valid)

proc call*(call_611840: Call_DeleteAccount_611828; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611841 = newJObject()
  add(path_611841, "accountId", newJString(accountId))
  result = call_611840.call(path_611841, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_611828(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_611829,
    base: "/", url: url_DeleteAccount_611830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttendee_611842 = ref object of OpenApiRestCall_610658
proc url_GetAttendee_611844(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAttendee_611843(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611845 = path.getOrDefault("attendeeId")
  valid_611845 = validateParameter(valid_611845, JString, required = true,
                                 default = nil)
  if valid_611845 != nil:
    section.add "attendeeId", valid_611845
  var valid_611846 = path.getOrDefault("meetingId")
  valid_611846 = validateParameter(valid_611846, JString, required = true,
                                 default = nil)
  if valid_611846 != nil:
    section.add "meetingId", valid_611846
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
  var valid_611847 = header.getOrDefault("X-Amz-Signature")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Signature", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Content-Sha256", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Date")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Date", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Credential")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Credential", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Security-Token")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Security-Token", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Algorithm")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Algorithm", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-SignedHeaders", valid_611853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611854: Call_GetAttendee_611842; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611854.validator(path, query, header, formData, body)
  let scheme = call_611854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611854.url(scheme.get, call_611854.host, call_611854.base,
                         call_611854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611854, url, valid)

proc call*(call_611855: Call_GetAttendee_611842; attendeeId: string;
          meetingId: string): Recallable =
  ## getAttendee
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_611856 = newJObject()
  add(path_611856, "attendeeId", newJString(attendeeId))
  add(path_611856, "meetingId", newJString(meetingId))
  result = call_611855.call(path_611856, nil, nil, nil, nil)

var getAttendee* = Call_GetAttendee_611842(name: "getAttendee",
                                        meth: HttpMethod.HttpGet,
                                        host: "chime.amazonaws.com", route: "/meetings/{meetingId}/attendees/{attendeeId}",
                                        validator: validate_GetAttendee_611843,
                                        base: "/", url: url_GetAttendee_611844,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttendee_611857 = ref object of OpenApiRestCall_610658
proc url_DeleteAttendee_611859(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAttendee_611858(path: JsonNode; query: JsonNode;
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
  var valid_611860 = path.getOrDefault("attendeeId")
  valid_611860 = validateParameter(valid_611860, JString, required = true,
                                 default = nil)
  if valid_611860 != nil:
    section.add "attendeeId", valid_611860
  var valid_611861 = path.getOrDefault("meetingId")
  valid_611861 = validateParameter(valid_611861, JString, required = true,
                                 default = nil)
  if valid_611861 != nil:
    section.add "meetingId", valid_611861
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
  var valid_611862 = header.getOrDefault("X-Amz-Signature")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Signature", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Content-Sha256", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Date")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Date", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Credential")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Credential", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Security-Token")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Security-Token", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Algorithm")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Algorithm", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-SignedHeaders", valid_611868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611869: Call_DeleteAttendee_611857; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611869.validator(path, query, header, formData, body)
  let scheme = call_611869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611869.url(scheme.get, call_611869.host, call_611869.base,
                         call_611869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611869, url, valid)

proc call*(call_611870: Call_DeleteAttendee_611857; attendeeId: string;
          meetingId: string): Recallable =
  ## deleteAttendee
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_611871 = newJObject()
  add(path_611871, "attendeeId", newJString(attendeeId))
  add(path_611871, "meetingId", newJString(meetingId))
  result = call_611870.call(path_611871, nil, nil, nil, nil)

var deleteAttendee* = Call_DeleteAttendee_611857(name: "deleteAttendee",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees/{attendeeId}",
    validator: validate_DeleteAttendee_611858, base: "/", url: url_DeleteAttendee_611859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_611887 = ref object of OpenApiRestCall_610658
proc url_PutEventsConfiguration_611889(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEventsConfiguration_611888(path: JsonNode; query: JsonNode;
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
  var valid_611890 = path.getOrDefault("botId")
  valid_611890 = validateParameter(valid_611890, JString, required = true,
                                 default = nil)
  if valid_611890 != nil:
    section.add "botId", valid_611890
  var valid_611891 = path.getOrDefault("accountId")
  valid_611891 = validateParameter(valid_611891, JString, required = true,
                                 default = nil)
  if valid_611891 != nil:
    section.add "accountId", valid_611891
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
  var valid_611892 = header.getOrDefault("X-Amz-Signature")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Signature", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Content-Sha256", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Date")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Date", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Credential")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Credential", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Security-Token")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Security-Token", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Algorithm")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Algorithm", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-SignedHeaders", valid_611898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611900: Call_PutEventsConfiguration_611887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_611900.validator(path, query, header, formData, body)
  let scheme = call_611900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611900.url(scheme.get, call_611900.host, call_611900.base,
                         call_611900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611900, url, valid)

proc call*(call_611901: Call_PutEventsConfiguration_611887; botId: string;
          body: JsonNode; accountId: string): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611902 = newJObject()
  var body_611903 = newJObject()
  add(path_611902, "botId", newJString(botId))
  if body != nil:
    body_611903 = body
  add(path_611902, "accountId", newJString(accountId))
  result = call_611901.call(path_611902, nil, nil, nil, body_611903)

var putEventsConfiguration* = Call_PutEventsConfiguration_611887(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_611888, base: "/",
    url: url_PutEventsConfiguration_611889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_611872 = ref object of OpenApiRestCall_610658
proc url_GetEventsConfiguration_611874(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventsConfiguration_611873(path: JsonNode; query: JsonNode;
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
  var valid_611875 = path.getOrDefault("botId")
  valid_611875 = validateParameter(valid_611875, JString, required = true,
                                 default = nil)
  if valid_611875 != nil:
    section.add "botId", valid_611875
  var valid_611876 = path.getOrDefault("accountId")
  valid_611876 = validateParameter(valid_611876, JString, required = true,
                                 default = nil)
  if valid_611876 != nil:
    section.add "accountId", valid_611876
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
  var valid_611877 = header.getOrDefault("X-Amz-Signature")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Signature", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Content-Sha256", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Date")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Date", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Credential")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Credential", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Security-Token")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Security-Token", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Algorithm")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Algorithm", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-SignedHeaders", valid_611883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611884: Call_GetEventsConfiguration_611872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_611884.validator(path, query, header, formData, body)
  let scheme = call_611884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611884.url(scheme.get, call_611884.host, call_611884.base,
                         call_611884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611884, url, valid)

proc call*(call_611885: Call_GetEventsConfiguration_611872; botId: string;
          accountId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611886 = newJObject()
  add(path_611886, "botId", newJString(botId))
  add(path_611886, "accountId", newJString(accountId))
  result = call_611885.call(path_611886, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_611872(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_611873, base: "/",
    url: url_GetEventsConfiguration_611874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_611904 = ref object of OpenApiRestCall_610658
proc url_DeleteEventsConfiguration_611906(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEventsConfiguration_611905(path: JsonNode; query: JsonNode;
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
  var valid_611907 = path.getOrDefault("botId")
  valid_611907 = validateParameter(valid_611907, JString, required = true,
                                 default = nil)
  if valid_611907 != nil:
    section.add "botId", valid_611907
  var valid_611908 = path.getOrDefault("accountId")
  valid_611908 = validateParameter(valid_611908, JString, required = true,
                                 default = nil)
  if valid_611908 != nil:
    section.add "accountId", valid_611908
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
  var valid_611909 = header.getOrDefault("X-Amz-Signature")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Signature", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Content-Sha256", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Date")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Date", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Credential")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Credential", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Security-Token")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Security-Token", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Algorithm")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Algorithm", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-SignedHeaders", valid_611915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611916: Call_DeleteEventsConfiguration_611904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_611916.validator(path, query, header, formData, body)
  let scheme = call_611916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611916.url(scheme.get, call_611916.host, call_611916.base,
                         call_611916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611916, url, valid)

proc call*(call_611917: Call_DeleteEventsConfiguration_611904; botId: string;
          accountId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_611918 = newJObject()
  add(path_611918, "botId", newJString(botId))
  add(path_611918, "accountId", newJString(accountId))
  result = call_611917.call(path_611918, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_611904(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_611905, base: "/",
    url: url_DeleteEventsConfiguration_611906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMeeting_611919 = ref object of OpenApiRestCall_610658
proc url_GetMeeting_611921(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMeeting_611920(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611922 = path.getOrDefault("meetingId")
  valid_611922 = validateParameter(valid_611922, JString, required = true,
                                 default = nil)
  if valid_611922 != nil:
    section.add "meetingId", valid_611922
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
  var valid_611923 = header.getOrDefault("X-Amz-Signature")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Signature", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Content-Sha256", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Date")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Date", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Credential")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Credential", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Security-Token")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Security-Token", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Algorithm")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Algorithm", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-SignedHeaders", valid_611929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611930: Call_GetMeeting_611919; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611930.validator(path, query, header, formData, body)
  let scheme = call_611930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611930.url(scheme.get, call_611930.host, call_611930.base,
                         call_611930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611930, url, valid)

proc call*(call_611931: Call_GetMeeting_611919; meetingId: string): Recallable =
  ## getMeeting
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_611932 = newJObject()
  add(path_611932, "meetingId", newJString(meetingId))
  result = call_611931.call(path_611932, nil, nil, nil, nil)

var getMeeting* = Call_GetMeeting_611919(name: "getMeeting",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/meetings/{meetingId}",
                                      validator: validate_GetMeeting_611920,
                                      base: "/", url: url_GetMeeting_611921,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMeeting_611933 = ref object of OpenApiRestCall_610658
proc url_DeleteMeeting_611935(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMeeting_611934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611936 = path.getOrDefault("meetingId")
  valid_611936 = validateParameter(valid_611936, JString, required = true,
                                 default = nil)
  if valid_611936 != nil:
    section.add "meetingId", valid_611936
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
  var valid_611937 = header.getOrDefault("X-Amz-Signature")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Signature", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Content-Sha256", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-Date")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-Date", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Credential")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Credential", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Security-Token")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Security-Token", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-Algorithm")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-Algorithm", valid_611942
  var valid_611943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-SignedHeaders", valid_611943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611944: Call_DeleteMeeting_611933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_611944.validator(path, query, header, formData, body)
  let scheme = call_611944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611944.url(scheme.get, call_611944.host, call_611944.base,
                         call_611944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611944, url, valid)

proc call*(call_611945: Call_DeleteMeeting_611933; meetingId: string): Recallable =
  ## deleteMeeting
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_611946 = newJObject()
  add(path_611946, "meetingId", newJString(meetingId))
  result = call_611945.call(path_611946, nil, nil, nil, nil)

var deleteMeeting* = Call_DeleteMeeting_611933(name: "deleteMeeting",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}", validator: validate_DeleteMeeting_611934,
    base: "/", url: url_DeleteMeeting_611935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_611961 = ref object of OpenApiRestCall_610658
proc url_UpdatePhoneNumber_611963(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePhoneNumber_611962(path: JsonNode; query: JsonNode;
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
  var valid_611964 = path.getOrDefault("phoneNumberId")
  valid_611964 = validateParameter(valid_611964, JString, required = true,
                                 default = nil)
  if valid_611964 != nil:
    section.add "phoneNumberId", valid_611964
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
  var valid_611965 = header.getOrDefault("X-Amz-Signature")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-Signature", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Content-Sha256", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Date")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Date", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Credential")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Credential", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Security-Token")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Security-Token", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Algorithm")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Algorithm", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-SignedHeaders", valid_611971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611973: Call_UpdatePhoneNumber_611961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_611973.validator(path, query, header, formData, body)
  let scheme = call_611973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611973.url(scheme.get, call_611973.host, call_611973.base,
                         call_611973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611973, url, valid)

proc call*(call_611974: Call_UpdatePhoneNumber_611961; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_611975 = newJObject()
  var body_611976 = newJObject()
  add(path_611975, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_611976 = body
  result = call_611974.call(path_611975, nil, nil, nil, body_611976)

var updatePhoneNumber* = Call_UpdatePhoneNumber_611961(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_611962, base: "/",
    url: url_UpdatePhoneNumber_611963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_611947 = ref object of OpenApiRestCall_610658
proc url_GetPhoneNumber_611949(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPhoneNumber_611948(path: JsonNode; query: JsonNode;
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
  var valid_611950 = path.getOrDefault("phoneNumberId")
  valid_611950 = validateParameter(valid_611950, JString, required = true,
                                 default = nil)
  if valid_611950 != nil:
    section.add "phoneNumberId", valid_611950
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
  var valid_611951 = header.getOrDefault("X-Amz-Signature")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Signature", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Content-Sha256", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Date")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Date", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Credential")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Credential", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Security-Token")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Security-Token", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-Algorithm")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Algorithm", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-SignedHeaders", valid_611957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611958: Call_GetPhoneNumber_611947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_611958.validator(path, query, header, formData, body)
  let scheme = call_611958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611958.url(scheme.get, call_611958.host, call_611958.base,
                         call_611958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611958, url, valid)

proc call*(call_611959: Call_GetPhoneNumber_611947; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_611960 = newJObject()
  add(path_611960, "phoneNumberId", newJString(phoneNumberId))
  result = call_611959.call(path_611960, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_611947(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_611948,
    base: "/", url: url_GetPhoneNumber_611949, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_611977 = ref object of OpenApiRestCall_610658
proc url_DeletePhoneNumber_611979(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePhoneNumber_611978(path: JsonNode; query: JsonNode;
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
  var valid_611980 = path.getOrDefault("phoneNumberId")
  valid_611980 = validateParameter(valid_611980, JString, required = true,
                                 default = nil)
  if valid_611980 != nil:
    section.add "phoneNumberId", valid_611980
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
  var valid_611981 = header.getOrDefault("X-Amz-Signature")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-Signature", valid_611981
  var valid_611982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-Content-Sha256", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Date")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Date", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-Credential")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-Credential", valid_611984
  var valid_611985 = header.getOrDefault("X-Amz-Security-Token")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Security-Token", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Algorithm")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Algorithm", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-SignedHeaders", valid_611987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611988: Call_DeletePhoneNumber_611977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_611988.validator(path, query, header, formData, body)
  let scheme = call_611988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611988.url(scheme.get, call_611988.host, call_611988.base,
                         call_611988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611988, url, valid)

proc call*(call_611989: Call_DeletePhoneNumber_611977; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_611990 = newJObject()
  add(path_611990, "phoneNumberId", newJString(phoneNumberId))
  result = call_611989.call(path_611990, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_611977(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_611978, base: "/",
    url: url_DeletePhoneNumber_611979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_612006 = ref object of OpenApiRestCall_610658
proc url_UpdateRoom_612008(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoom_612007(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates room details, such as the room name, for a room in an Amazon Chime Enterprise account.
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
  var valid_612009 = path.getOrDefault("accountId")
  valid_612009 = validateParameter(valid_612009, JString, required = true,
                                 default = nil)
  if valid_612009 != nil:
    section.add "accountId", valid_612009
  var valid_612010 = path.getOrDefault("roomId")
  valid_612010 = validateParameter(valid_612010, JString, required = true,
                                 default = nil)
  if valid_612010 != nil:
    section.add "roomId", valid_612010
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
  var valid_612011 = header.getOrDefault("X-Amz-Signature")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Signature", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Content-Sha256", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Date")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Date", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Credential")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Credential", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Security-Token")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Security-Token", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Algorithm")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Algorithm", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-SignedHeaders", valid_612017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612019: Call_UpdateRoom_612006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_612019.validator(path, query, header, formData, body)
  let scheme = call_612019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612019.url(scheme.get, call_612019.host, call_612019.base,
                         call_612019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612019, url, valid)

proc call*(call_612020: Call_UpdateRoom_612006; body: JsonNode; accountId: string;
          roomId: string): Recallable =
  ## updateRoom
  ## Updates room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_612021 = newJObject()
  var body_612022 = newJObject()
  if body != nil:
    body_612022 = body
  add(path_612021, "accountId", newJString(accountId))
  add(path_612021, "roomId", newJString(roomId))
  result = call_612020.call(path_612021, nil, nil, nil, body_612022)

var updateRoom* = Call_UpdateRoom_612006(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_UpdateRoom_612007,
                                      base: "/", url: url_UpdateRoom_612008,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_611991 = ref object of OpenApiRestCall_610658
proc url_GetRoom_611993(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRoom_611992(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves room details, such as the room name, for a room in an Amazon Chime Enterprise account.
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
  var valid_611994 = path.getOrDefault("accountId")
  valid_611994 = validateParameter(valid_611994, JString, required = true,
                                 default = nil)
  if valid_611994 != nil:
    section.add "accountId", valid_611994
  var valid_611995 = path.getOrDefault("roomId")
  valid_611995 = validateParameter(valid_611995, JString, required = true,
                                 default = nil)
  if valid_611995 != nil:
    section.add "roomId", valid_611995
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
  var valid_611996 = header.getOrDefault("X-Amz-Signature")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-Signature", valid_611996
  var valid_611997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Content-Sha256", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-Date")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Date", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-Credential")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-Credential", valid_611999
  var valid_612000 = header.getOrDefault("X-Amz-Security-Token")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Security-Token", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Algorithm")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Algorithm", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-SignedHeaders", valid_612002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612003: Call_GetRoom_611991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_612003.validator(path, query, header, formData, body)
  let scheme = call_612003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612003.url(scheme.get, call_612003.host, call_612003.base,
                         call_612003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612003, url, valid)

proc call*(call_612004: Call_GetRoom_611991; accountId: string; roomId: string): Recallable =
  ## getRoom
  ## Retrieves room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_612005 = newJObject()
  add(path_612005, "accountId", newJString(accountId))
  add(path_612005, "roomId", newJString(roomId))
  result = call_612004.call(path_612005, nil, nil, nil, nil)

var getRoom* = Call_GetRoom_611991(name: "getRoom", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/rooms/{roomId}",
                                validator: validate_GetRoom_611992, base: "/",
                                url: url_GetRoom_611993,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_612023 = ref object of OpenApiRestCall_610658
proc url_DeleteRoom_612025(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoom_612024(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a chat room in an Amazon Chime Enterprise account.
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
  var valid_612026 = path.getOrDefault("accountId")
  valid_612026 = validateParameter(valid_612026, JString, required = true,
                                 default = nil)
  if valid_612026 != nil:
    section.add "accountId", valid_612026
  var valid_612027 = path.getOrDefault("roomId")
  valid_612027 = validateParameter(valid_612027, JString, required = true,
                                 default = nil)
  if valid_612027 != nil:
    section.add "roomId", valid_612027
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
  var valid_612028 = header.getOrDefault("X-Amz-Signature")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Signature", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Content-Sha256", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Date")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Date", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Credential")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Credential", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Security-Token")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Security-Token", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-Algorithm")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-Algorithm", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-SignedHeaders", valid_612034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612035: Call_DeleteRoom_612023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a chat room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_612035.validator(path, query, header, formData, body)
  let scheme = call_612035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612035.url(scheme.get, call_612035.host, call_612035.base,
                         call_612035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612035, url, valid)

proc call*(call_612036: Call_DeleteRoom_612023; accountId: string; roomId: string): Recallable =
  ## deleteRoom
  ## Deletes a chat room in an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The chat room ID.
  var path_612037 = newJObject()
  add(path_612037, "accountId", newJString(accountId))
  add(path_612037, "roomId", newJString(roomId))
  result = call_612036.call(path_612037, nil, nil, nil, nil)

var deleteRoom* = Call_DeleteRoom_612023(name: "deleteRoom",
                                      meth: HttpMethod.HttpDelete,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_DeleteRoom_612024,
                                      base: "/", url: url_DeleteRoom_612025,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoomMembership_612038 = ref object of OpenApiRestCall_610658
proc url_UpdateRoomMembership_612040(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoomMembership_612039(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates room membership details, such as the member role, for a room in an Amazon Chime Enterprise account. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
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
  var valid_612041 = path.getOrDefault("memberId")
  valid_612041 = validateParameter(valid_612041, JString, required = true,
                                 default = nil)
  if valid_612041 != nil:
    section.add "memberId", valid_612041
  var valid_612042 = path.getOrDefault("accountId")
  valid_612042 = validateParameter(valid_612042, JString, required = true,
                                 default = nil)
  if valid_612042 != nil:
    section.add "accountId", valid_612042
  var valid_612043 = path.getOrDefault("roomId")
  valid_612043 = validateParameter(valid_612043, JString, required = true,
                                 default = nil)
  if valid_612043 != nil:
    section.add "roomId", valid_612043
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
  var valid_612044 = header.getOrDefault("X-Amz-Signature")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Signature", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Content-Sha256", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Date")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Date", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-Credential")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-Credential", valid_612047
  var valid_612048 = header.getOrDefault("X-Amz-Security-Token")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-Security-Token", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-Algorithm")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Algorithm", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-SignedHeaders", valid_612050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612052: Call_UpdateRoomMembership_612038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room membership details, such as the member role, for a room in an Amazon Chime Enterprise account. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ## 
  let valid = call_612052.validator(path, query, header, formData, body)
  let scheme = call_612052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612052.url(scheme.get, call_612052.host, call_612052.base,
                         call_612052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612052, url, valid)

proc call*(call_612053: Call_UpdateRoomMembership_612038; memberId: string;
          body: JsonNode; accountId: string; roomId: string): Recallable =
  ## updateRoomMembership
  ## Updates room membership details, such as the member role, for a room in an Amazon Chime Enterprise account. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ##   memberId: string (required)
  ##           : The member ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_612054 = newJObject()
  var body_612055 = newJObject()
  add(path_612054, "memberId", newJString(memberId))
  if body != nil:
    body_612055 = body
  add(path_612054, "accountId", newJString(accountId))
  add(path_612054, "roomId", newJString(roomId))
  result = call_612053.call(path_612054, nil, nil, nil, body_612055)

var updateRoomMembership* = Call_UpdateRoomMembership_612038(
    name: "updateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_UpdateRoomMembership_612039, base: "/",
    url: url_UpdateRoomMembership_612040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomMembership_612056 = ref object of OpenApiRestCall_610658
proc url_DeleteRoomMembership_612058(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoomMembership_612057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a member from a chat room in an Amazon Chime Enterprise account.
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
  var valid_612059 = path.getOrDefault("memberId")
  valid_612059 = validateParameter(valid_612059, JString, required = true,
                                 default = nil)
  if valid_612059 != nil:
    section.add "memberId", valid_612059
  var valid_612060 = path.getOrDefault("accountId")
  valid_612060 = validateParameter(valid_612060, JString, required = true,
                                 default = nil)
  if valid_612060 != nil:
    section.add "accountId", valid_612060
  var valid_612061 = path.getOrDefault("roomId")
  valid_612061 = validateParameter(valid_612061, JString, required = true,
                                 default = nil)
  if valid_612061 != nil:
    section.add "roomId", valid_612061
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
  var valid_612062 = header.getOrDefault("X-Amz-Signature")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Signature", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Content-Sha256", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Date")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Date", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Credential")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Credential", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Security-Token")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Security-Token", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Algorithm")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Algorithm", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-SignedHeaders", valid_612068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612069: Call_DeleteRoomMembership_612056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a member from a chat room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_612069.validator(path, query, header, formData, body)
  let scheme = call_612069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612069.url(scheme.get, call_612069.host, call_612069.base,
                         call_612069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612069, url, valid)

proc call*(call_612070: Call_DeleteRoomMembership_612056; memberId: string;
          accountId: string; roomId: string): Recallable =
  ## deleteRoomMembership
  ## Removes a member from a chat room in an Amazon Chime Enterprise account.
  ##   memberId: string (required)
  ##           : The member ID (user ID or bot ID).
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_612071 = newJObject()
  add(path_612071, "memberId", newJString(memberId))
  add(path_612071, "accountId", newJString(accountId))
  add(path_612071, "roomId", newJString(roomId))
  result = call_612070.call(path_612071, nil, nil, nil, nil)

var deleteRoomMembership* = Call_DeleteRoomMembership_612056(
    name: "deleteRoomMembership", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_DeleteRoomMembership_612057, base: "/",
    url: url_DeleteRoomMembership_612058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_612086 = ref object of OpenApiRestCall_610658
proc url_UpdateVoiceConnector_612088(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceConnector_612087(path: JsonNode; query: JsonNode;
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
  var valid_612089 = path.getOrDefault("voiceConnectorId")
  valid_612089 = validateParameter(valid_612089, JString, required = true,
                                 default = nil)
  if valid_612089 != nil:
    section.add "voiceConnectorId", valid_612089
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
  var valid_612090 = header.getOrDefault("X-Amz-Signature")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Signature", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Content-Sha256", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Date")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Date", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Credential")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Credential", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Security-Token")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Security-Token", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-Algorithm")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-Algorithm", valid_612095
  var valid_612096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612096 = validateParameter(valid_612096, JString, required = false,
                                 default = nil)
  if valid_612096 != nil:
    section.add "X-Amz-SignedHeaders", valid_612096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612098: Call_UpdateVoiceConnector_612086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612098.validator(path, query, header, formData, body)
  let scheme = call_612098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612098.url(scheme.get, call_612098.host, call_612098.base,
                         call_612098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612098, url, valid)

proc call*(call_612099: Call_UpdateVoiceConnector_612086; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612100 = newJObject()
  var body_612101 = newJObject()
  add(path_612100, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612101 = body
  result = call_612099.call(path_612100, nil, nil, nil, body_612101)

var updateVoiceConnector* = Call_UpdateVoiceConnector_612086(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_612087, base: "/",
    url: url_UpdateVoiceConnector_612088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_612072 = ref object of OpenApiRestCall_610658
proc url_GetVoiceConnector_612074(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnector_612073(path: JsonNode; query: JsonNode;
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
  var valid_612075 = path.getOrDefault("voiceConnectorId")
  valid_612075 = validateParameter(valid_612075, JString, required = true,
                                 default = nil)
  if valid_612075 != nil:
    section.add "voiceConnectorId", valid_612075
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
  var valid_612076 = header.getOrDefault("X-Amz-Signature")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Signature", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-Content-Sha256", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Date")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Date", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Credential")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Credential", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Security-Token")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Security-Token", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-Algorithm")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-Algorithm", valid_612081
  var valid_612082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "X-Amz-SignedHeaders", valid_612082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612083: Call_GetVoiceConnector_612072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_612083.validator(path, query, header, formData, body)
  let scheme = call_612083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612083.url(scheme.get, call_612083.host, call_612083.base,
                         call_612083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612083, url, valid)

proc call*(call_612084: Call_GetVoiceConnector_612072; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612085 = newJObject()
  add(path_612085, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612084.call(path_612085, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_612072(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_612073, base: "/",
    url: url_GetVoiceConnector_612074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_612102 = ref object of OpenApiRestCall_610658
proc url_DeleteVoiceConnector_612104(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnector_612103(path: JsonNode; query: JsonNode;
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
  var valid_612105 = path.getOrDefault("voiceConnectorId")
  valid_612105 = validateParameter(valid_612105, JString, required = true,
                                 default = nil)
  if valid_612105 != nil:
    section.add "voiceConnectorId", valid_612105
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
  var valid_612106 = header.getOrDefault("X-Amz-Signature")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Signature", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Content-Sha256", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-Date")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Date", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-Credential")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-Credential", valid_612109
  var valid_612110 = header.getOrDefault("X-Amz-Security-Token")
  valid_612110 = validateParameter(valid_612110, JString, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "X-Amz-Security-Token", valid_612110
  var valid_612111 = header.getOrDefault("X-Amz-Algorithm")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "X-Amz-Algorithm", valid_612111
  var valid_612112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-SignedHeaders", valid_612112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612113: Call_DeleteVoiceConnector_612102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  let valid = call_612113.validator(path, query, header, formData, body)
  let scheme = call_612113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612113.url(scheme.get, call_612113.host, call_612113.base,
                         call_612113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612113, url, valid)

proc call*(call_612114: Call_DeleteVoiceConnector_612102; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612115 = newJObject()
  add(path_612115, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612114.call(path_612115, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_612102(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_612103, base: "/",
    url: url_DeleteVoiceConnector_612104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnectorGroup_612130 = ref object of OpenApiRestCall_610658
proc url_UpdateVoiceConnectorGroup_612132(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVoiceConnectorGroup_612131(path: JsonNode; query: JsonNode;
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
  var valid_612133 = path.getOrDefault("voiceConnectorGroupId")
  valid_612133 = validateParameter(valid_612133, JString, required = true,
                                 default = nil)
  if valid_612133 != nil:
    section.add "voiceConnectorGroupId", valid_612133
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
  var valid_612134 = header.getOrDefault("X-Amz-Signature")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Signature", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Content-Sha256", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Date")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Date", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-Credential")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Credential", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-Security-Token")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-Security-Token", valid_612138
  var valid_612139 = header.getOrDefault("X-Amz-Algorithm")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Algorithm", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-SignedHeaders", valid_612140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612142: Call_UpdateVoiceConnectorGroup_612130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  let valid = call_612142.validator(path, query, header, formData, body)
  let scheme = call_612142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612142.url(scheme.get, call_612142.host, call_612142.base,
                         call_612142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612142, url, valid)

proc call*(call_612143: Call_UpdateVoiceConnectorGroup_612130;
          voiceConnectorGroupId: string; body: JsonNode): Recallable =
  ## updateVoiceConnectorGroup
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   body: JObject (required)
  var path_612144 = newJObject()
  var body_612145 = newJObject()
  add(path_612144, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  if body != nil:
    body_612145 = body
  result = call_612143.call(path_612144, nil, nil, nil, body_612145)

var updateVoiceConnectorGroup* = Call_UpdateVoiceConnectorGroup_612130(
    name: "updateVoiceConnectorGroup", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_UpdateVoiceConnectorGroup_612131, base: "/",
    url: url_UpdateVoiceConnectorGroup_612132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorGroup_612116 = ref object of OpenApiRestCall_610658
proc url_GetVoiceConnectorGroup_612118(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorGroup_612117(path: JsonNode; query: JsonNode;
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
  var valid_612119 = path.getOrDefault("voiceConnectorGroupId")
  valid_612119 = validateParameter(valid_612119, JString, required = true,
                                 default = nil)
  if valid_612119 != nil:
    section.add "voiceConnectorGroupId", valid_612119
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
  var valid_612120 = header.getOrDefault("X-Amz-Signature")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "X-Amz-Signature", valid_612120
  var valid_612121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "X-Amz-Content-Sha256", valid_612121
  var valid_612122 = header.getOrDefault("X-Amz-Date")
  valid_612122 = validateParameter(valid_612122, JString, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "X-Amz-Date", valid_612122
  var valid_612123 = header.getOrDefault("X-Amz-Credential")
  valid_612123 = validateParameter(valid_612123, JString, required = false,
                                 default = nil)
  if valid_612123 != nil:
    section.add "X-Amz-Credential", valid_612123
  var valid_612124 = header.getOrDefault("X-Amz-Security-Token")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-Security-Token", valid_612124
  var valid_612125 = header.getOrDefault("X-Amz-Algorithm")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "X-Amz-Algorithm", valid_612125
  var valid_612126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "X-Amz-SignedHeaders", valid_612126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612127: Call_GetVoiceConnectorGroup_612116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  let valid = call_612127.validator(path, query, header, formData, body)
  let scheme = call_612127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612127.url(scheme.get, call_612127.host, call_612127.base,
                         call_612127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612127, url, valid)

proc call*(call_612128: Call_GetVoiceConnectorGroup_612116;
          voiceConnectorGroupId: string): Recallable =
  ## getVoiceConnectorGroup
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_612129 = newJObject()
  add(path_612129, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_612128.call(path_612129, nil, nil, nil, nil)

var getVoiceConnectorGroup* = Call_GetVoiceConnectorGroup_612116(
    name: "getVoiceConnectorGroup", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_GetVoiceConnectorGroup_612117, base: "/",
    url: url_GetVoiceConnectorGroup_612118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorGroup_612146 = ref object of OpenApiRestCall_610658
proc url_DeleteVoiceConnectorGroup_612148(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorGroup_612147(path: JsonNode; query: JsonNode;
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
  var valid_612149 = path.getOrDefault("voiceConnectorGroupId")
  valid_612149 = validateParameter(valid_612149, JString, required = true,
                                 default = nil)
  if valid_612149 != nil:
    section.add "voiceConnectorGroupId", valid_612149
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
  var valid_612150 = header.getOrDefault("X-Amz-Signature")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Signature", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Content-Sha256", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-Date")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Date", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Credential")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Credential", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Security-Token")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Security-Token", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-Algorithm")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-Algorithm", valid_612155
  var valid_612156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "X-Amz-SignedHeaders", valid_612156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612157: Call_DeleteVoiceConnectorGroup_612146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  let valid = call_612157.validator(path, query, header, formData, body)
  let scheme = call_612157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612157.url(scheme.get, call_612157.host, call_612157.base,
                         call_612157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612157, url, valid)

proc call*(call_612158: Call_DeleteVoiceConnectorGroup_612146;
          voiceConnectorGroupId: string): Recallable =
  ## deleteVoiceConnectorGroup
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_612159 = newJObject()
  add(path_612159, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_612158.call(path_612159, nil, nil, nil, nil)

var deleteVoiceConnectorGroup* = Call_DeleteVoiceConnectorGroup_612146(
    name: "deleteVoiceConnectorGroup", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_DeleteVoiceConnectorGroup_612147, base: "/",
    url: url_DeleteVoiceConnectorGroup_612148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_612174 = ref object of OpenApiRestCall_610658
proc url_PutVoiceConnectorOrigination_612176(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorOrigination_612175(path: JsonNode; query: JsonNode;
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
  var valid_612177 = path.getOrDefault("voiceConnectorId")
  valid_612177 = validateParameter(valid_612177, JString, required = true,
                                 default = nil)
  if valid_612177 != nil:
    section.add "voiceConnectorId", valid_612177
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
  var valid_612178 = header.getOrDefault("X-Amz-Signature")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Signature", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Content-Sha256", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Date")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Date", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Credential")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Credential", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Security-Token")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Security-Token", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Algorithm")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Algorithm", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-SignedHeaders", valid_612184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612186: Call_PutVoiceConnectorOrigination_612174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612186.validator(path, query, header, formData, body)
  let scheme = call_612186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612186.url(scheme.get, call_612186.host, call_612186.base,
                         call_612186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612186, url, valid)

proc call*(call_612187: Call_PutVoiceConnectorOrigination_612174;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612188 = newJObject()
  var body_612189 = newJObject()
  add(path_612188, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612189 = body
  result = call_612187.call(path_612188, nil, nil, nil, body_612189)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_612174(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_612175, base: "/",
    url: url_PutVoiceConnectorOrigination_612176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_612160 = ref object of OpenApiRestCall_610658
proc url_GetVoiceConnectorOrigination_612162(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorOrigination_612161(path: JsonNode; query: JsonNode;
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
  var valid_612163 = path.getOrDefault("voiceConnectorId")
  valid_612163 = validateParameter(valid_612163, JString, required = true,
                                 default = nil)
  if valid_612163 != nil:
    section.add "voiceConnectorId", valid_612163
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
  var valid_612164 = header.getOrDefault("X-Amz-Signature")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Signature", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Content-Sha256", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Date")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Date", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Credential")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Credential", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-Security-Token")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Security-Token", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-Algorithm")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-Algorithm", valid_612169
  var valid_612170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-SignedHeaders", valid_612170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612171: Call_GetVoiceConnectorOrigination_612160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612171.validator(path, query, header, formData, body)
  let scheme = call_612171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612171.url(scheme.get, call_612171.host, call_612171.base,
                         call_612171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612171, url, valid)

proc call*(call_612172: Call_GetVoiceConnectorOrigination_612160;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612173 = newJObject()
  add(path_612173, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612172.call(path_612173, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_612160(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_612161, base: "/",
    url: url_GetVoiceConnectorOrigination_612162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_612190 = ref object of OpenApiRestCall_610658
proc url_DeleteVoiceConnectorOrigination_612192(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorOrigination_612191(path: JsonNode;
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
  var valid_612193 = path.getOrDefault("voiceConnectorId")
  valid_612193 = validateParameter(valid_612193, JString, required = true,
                                 default = nil)
  if valid_612193 != nil:
    section.add "voiceConnectorId", valid_612193
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
  var valid_612194 = header.getOrDefault("X-Amz-Signature")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Signature", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Content-Sha256", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-Date")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-Date", valid_612196
  var valid_612197 = header.getOrDefault("X-Amz-Credential")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Credential", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Security-Token")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Security-Token", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Algorithm")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Algorithm", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-SignedHeaders", valid_612200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612201: Call_DeleteVoiceConnectorOrigination_612190;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612201.validator(path, query, header, formData, body)
  let scheme = call_612201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612201.url(scheme.get, call_612201.host, call_612201.base,
                         call_612201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612201, url, valid)

proc call*(call_612202: Call_DeleteVoiceConnectorOrigination_612190;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612203 = newJObject()
  add(path_612203, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612202.call(path_612203, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_612190(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_612191, base: "/",
    url: url_DeleteVoiceConnectorOrigination_612192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorStreamingConfiguration_612218 = ref object of OpenApiRestCall_610658
proc url_PutVoiceConnectorStreamingConfiguration_612220(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorStreamingConfiguration_612219(path: JsonNode;
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
  var valid_612221 = path.getOrDefault("voiceConnectorId")
  valid_612221 = validateParameter(valid_612221, JString, required = true,
                                 default = nil)
  if valid_612221 != nil:
    section.add "voiceConnectorId", valid_612221
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
  var valid_612222 = header.getOrDefault("X-Amz-Signature")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-Signature", valid_612222
  var valid_612223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612223 = validateParameter(valid_612223, JString, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "X-Amz-Content-Sha256", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-Date")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-Date", valid_612224
  var valid_612225 = header.getOrDefault("X-Amz-Credential")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-Credential", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-Security-Token")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Security-Token", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-Algorithm")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Algorithm", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-SignedHeaders", valid_612228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612230: Call_PutVoiceConnectorStreamingConfiguration_612218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_612230.validator(path, query, header, formData, body)
  let scheme = call_612230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612230.url(scheme.get, call_612230.host, call_612230.base,
                         call_612230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612230, url, valid)

proc call*(call_612231: Call_PutVoiceConnectorStreamingConfiguration_612218;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorStreamingConfiguration
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612232 = newJObject()
  var body_612233 = newJObject()
  add(path_612232, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612233 = body
  result = call_612231.call(path_612232, nil, nil, nil, body_612233)

var putVoiceConnectorStreamingConfiguration* = Call_PutVoiceConnectorStreamingConfiguration_612218(
    name: "putVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_PutVoiceConnectorStreamingConfiguration_612219, base: "/",
    url: url_PutVoiceConnectorStreamingConfiguration_612220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorStreamingConfiguration_612204 = ref object of OpenApiRestCall_610658
proc url_GetVoiceConnectorStreamingConfiguration_612206(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorStreamingConfiguration_612205(path: JsonNode;
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
  var valid_612207 = path.getOrDefault("voiceConnectorId")
  valid_612207 = validateParameter(valid_612207, JString, required = true,
                                 default = nil)
  if valid_612207 != nil:
    section.add "voiceConnectorId", valid_612207
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
  var valid_612208 = header.getOrDefault("X-Amz-Signature")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "X-Amz-Signature", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Content-Sha256", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Date")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Date", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Credential")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Credential", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Security-Token")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Security-Token", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Algorithm")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Algorithm", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-SignedHeaders", valid_612214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612215: Call_GetVoiceConnectorStreamingConfiguration_612204;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_612215.validator(path, query, header, formData, body)
  let scheme = call_612215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612215.url(scheme.get, call_612215.host, call_612215.base,
                         call_612215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612215, url, valid)

proc call*(call_612216: Call_GetVoiceConnectorStreamingConfiguration_612204;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorStreamingConfiguration
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612217 = newJObject()
  add(path_612217, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612216.call(path_612217, nil, nil, nil, nil)

var getVoiceConnectorStreamingConfiguration* = Call_GetVoiceConnectorStreamingConfiguration_612204(
    name: "getVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_GetVoiceConnectorStreamingConfiguration_612205, base: "/",
    url: url_GetVoiceConnectorStreamingConfiguration_612206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorStreamingConfiguration_612234 = ref object of OpenApiRestCall_610658
proc url_DeleteVoiceConnectorStreamingConfiguration_612236(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorStreamingConfiguration_612235(path: JsonNode;
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
  var valid_612237 = path.getOrDefault("voiceConnectorId")
  valid_612237 = validateParameter(valid_612237, JString, required = true,
                                 default = nil)
  if valid_612237 != nil:
    section.add "voiceConnectorId", valid_612237
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
  var valid_612238 = header.getOrDefault("X-Amz-Signature")
  valid_612238 = validateParameter(valid_612238, JString, required = false,
                                 default = nil)
  if valid_612238 != nil:
    section.add "X-Amz-Signature", valid_612238
  var valid_612239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "X-Amz-Content-Sha256", valid_612239
  var valid_612240 = header.getOrDefault("X-Amz-Date")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "X-Amz-Date", valid_612240
  var valid_612241 = header.getOrDefault("X-Amz-Credential")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "X-Amz-Credential", valid_612241
  var valid_612242 = header.getOrDefault("X-Amz-Security-Token")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-Security-Token", valid_612242
  var valid_612243 = header.getOrDefault("X-Amz-Algorithm")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Algorithm", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-SignedHeaders", valid_612244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612245: Call_DeleteVoiceConnectorStreamingConfiguration_612234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612245.validator(path, query, header, formData, body)
  let scheme = call_612245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612245.url(scheme.get, call_612245.host, call_612245.base,
                         call_612245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612245, url, valid)

proc call*(call_612246: Call_DeleteVoiceConnectorStreamingConfiguration_612234;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorStreamingConfiguration
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612247 = newJObject()
  add(path_612247, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612246.call(path_612247, nil, nil, nil, nil)

var deleteVoiceConnectorStreamingConfiguration* = Call_DeleteVoiceConnectorStreamingConfiguration_612234(
    name: "deleteVoiceConnectorStreamingConfiguration",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_DeleteVoiceConnectorStreamingConfiguration_612235,
    base: "/", url: url_DeleteVoiceConnectorStreamingConfiguration_612236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_612262 = ref object of OpenApiRestCall_610658
proc url_PutVoiceConnectorTermination_612264(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorTermination_612263(path: JsonNode; query: JsonNode;
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
  var valid_612265 = path.getOrDefault("voiceConnectorId")
  valid_612265 = validateParameter(valid_612265, JString, required = true,
                                 default = nil)
  if valid_612265 != nil:
    section.add "voiceConnectorId", valid_612265
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
  var valid_612266 = header.getOrDefault("X-Amz-Signature")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Signature", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Content-Sha256", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-Date")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Date", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Credential")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Credential", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Security-Token")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Security-Token", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Algorithm")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Algorithm", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-SignedHeaders", valid_612272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612274: Call_PutVoiceConnectorTermination_612262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612274.validator(path, query, header, formData, body)
  let scheme = call_612274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612274.url(scheme.get, call_612274.host, call_612274.base,
                         call_612274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612274, url, valid)

proc call*(call_612275: Call_PutVoiceConnectorTermination_612262;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612276 = newJObject()
  var body_612277 = newJObject()
  add(path_612276, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612277 = body
  result = call_612275.call(path_612276, nil, nil, nil, body_612277)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_612262(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_612263, base: "/",
    url: url_PutVoiceConnectorTermination_612264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_612248 = ref object of OpenApiRestCall_610658
proc url_GetVoiceConnectorTermination_612250(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorTermination_612249(path: JsonNode; query: JsonNode;
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
  var valid_612251 = path.getOrDefault("voiceConnectorId")
  valid_612251 = validateParameter(valid_612251, JString, required = true,
                                 default = nil)
  if valid_612251 != nil:
    section.add "voiceConnectorId", valid_612251
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
  var valid_612252 = header.getOrDefault("X-Amz-Signature")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "X-Amz-Signature", valid_612252
  var valid_612253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-Content-Sha256", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Date")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Date", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Credential")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Credential", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-Security-Token")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Security-Token", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-Algorithm")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Algorithm", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-SignedHeaders", valid_612258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612259: Call_GetVoiceConnectorTermination_612248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612259.validator(path, query, header, formData, body)
  let scheme = call_612259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612259.url(scheme.get, call_612259.host, call_612259.base,
                         call_612259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612259, url, valid)

proc call*(call_612260: Call_GetVoiceConnectorTermination_612248;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612261 = newJObject()
  add(path_612261, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612260.call(path_612261, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_612248(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_612249, base: "/",
    url: url_GetVoiceConnectorTermination_612250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_612278 = ref object of OpenApiRestCall_610658
proc url_DeleteVoiceConnectorTermination_612280(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorTermination_612279(path: JsonNode;
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
  var valid_612281 = path.getOrDefault("voiceConnectorId")
  valid_612281 = validateParameter(valid_612281, JString, required = true,
                                 default = nil)
  if valid_612281 != nil:
    section.add "voiceConnectorId", valid_612281
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
  var valid_612282 = header.getOrDefault("X-Amz-Signature")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "X-Amz-Signature", valid_612282
  var valid_612283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Content-Sha256", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Date")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Date", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-Credential")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-Credential", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Security-Token")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Security-Token", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Algorithm")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Algorithm", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-SignedHeaders", valid_612288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612289: Call_DeleteVoiceConnectorTermination_612278;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612289.validator(path, query, header, formData, body)
  let scheme = call_612289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612289.url(scheme.get, call_612289.host, call_612289.base,
                         call_612289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612289, url, valid)

proc call*(call_612290: Call_DeleteVoiceConnectorTermination_612278;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612291 = newJObject()
  add(path_612291, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612290.call(path_612291, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_612278(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_612279, base: "/",
    url: url_DeleteVoiceConnectorTermination_612280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_612292 = ref object of OpenApiRestCall_610658
proc url_DeleteVoiceConnectorTerminationCredentials_612294(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorTerminationCredentials_612293(path: JsonNode;
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
  var valid_612295 = path.getOrDefault("voiceConnectorId")
  valid_612295 = validateParameter(valid_612295, JString, required = true,
                                 default = nil)
  if valid_612295 != nil:
    section.add "voiceConnectorId", valid_612295
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612296 = query.getOrDefault("operation")
  valid_612296 = validateParameter(valid_612296, JString, required = true,
                                 default = newJString("delete"))
  if valid_612296 != nil:
    section.add "operation", valid_612296
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
  var valid_612297 = header.getOrDefault("X-Amz-Signature")
  valid_612297 = validateParameter(valid_612297, JString, required = false,
                                 default = nil)
  if valid_612297 != nil:
    section.add "X-Amz-Signature", valid_612297
  var valid_612298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-Content-Sha256", valid_612298
  var valid_612299 = header.getOrDefault("X-Amz-Date")
  valid_612299 = validateParameter(valid_612299, JString, required = false,
                                 default = nil)
  if valid_612299 != nil:
    section.add "X-Amz-Date", valid_612299
  var valid_612300 = header.getOrDefault("X-Amz-Credential")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Credential", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Security-Token")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Security-Token", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Algorithm")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Algorithm", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-SignedHeaders", valid_612303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612305: Call_DeleteVoiceConnectorTerminationCredentials_612292;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_612305.validator(path, query, header, formData, body)
  let scheme = call_612305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612305.url(scheme.get, call_612305.host, call_612305.base,
                         call_612305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612305, url, valid)

proc call*(call_612306: Call_DeleteVoiceConnectorTerminationCredentials_612292;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612307 = newJObject()
  var query_612308 = newJObject()
  var body_612309 = newJObject()
  add(query_612308, "operation", newJString(operation))
  add(path_612307, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612309 = body
  result = call_612306.call(path_612307, query_612308, nil, nil, body_612309)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_612292(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_612293,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_612294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_612310 = ref object of OpenApiRestCall_610658
proc url_DisassociatePhoneNumberFromUser_612312(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociatePhoneNumberFromUser_612311(path: JsonNode;
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
  var valid_612313 = path.getOrDefault("userId")
  valid_612313 = validateParameter(valid_612313, JString, required = true,
                                 default = nil)
  if valid_612313 != nil:
    section.add "userId", valid_612313
  var valid_612314 = path.getOrDefault("accountId")
  valid_612314 = validateParameter(valid_612314, JString, required = true,
                                 default = nil)
  if valid_612314 != nil:
    section.add "accountId", valid_612314
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612315 = query.getOrDefault("operation")
  valid_612315 = validateParameter(valid_612315, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_612315 != nil:
    section.add "operation", valid_612315
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
  var valid_612316 = header.getOrDefault("X-Amz-Signature")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Signature", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Content-Sha256", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Date")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Date", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Credential")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Credential", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Security-Token")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Security-Token", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Algorithm")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Algorithm", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-SignedHeaders", valid_612322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612323: Call_DisassociatePhoneNumberFromUser_612310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_612323.validator(path, query, header, formData, body)
  let scheme = call_612323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612323.url(scheme.get, call_612323.host, call_612323.base,
                         call_612323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612323, url, valid)

proc call*(call_612324: Call_DisassociatePhoneNumberFromUser_612310;
          userId: string; accountId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612325 = newJObject()
  var query_612326 = newJObject()
  add(query_612326, "operation", newJString(operation))
  add(path_612325, "userId", newJString(userId))
  add(path_612325, "accountId", newJString(accountId))
  result = call_612324.call(path_612325, query_612326, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_612310(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_612311, base: "/",
    url: url_DisassociatePhoneNumberFromUser_612312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_612327 = ref object of OpenApiRestCall_610658
proc url_DisassociatePhoneNumbersFromVoiceConnector_612329(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociatePhoneNumbersFromVoiceConnector_612328(path: JsonNode;
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
  var valid_612330 = path.getOrDefault("voiceConnectorId")
  valid_612330 = validateParameter(valid_612330, JString, required = true,
                                 default = nil)
  if valid_612330 != nil:
    section.add "voiceConnectorId", valid_612330
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612331 = query.getOrDefault("operation")
  valid_612331 = validateParameter(valid_612331, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_612331 != nil:
    section.add "operation", valid_612331
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
  var valid_612332 = header.getOrDefault("X-Amz-Signature")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-Signature", valid_612332
  var valid_612333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Content-Sha256", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Date")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Date", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Credential")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Credential", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Security-Token")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Security-Token", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Algorithm")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Algorithm", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-SignedHeaders", valid_612338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612340: Call_DisassociatePhoneNumbersFromVoiceConnector_612327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612340.validator(path, query, header, formData, body)
  let scheme = call_612340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612340.url(scheme.get, call_612340.host, call_612340.base,
                         call_612340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612340, url, valid)

proc call*(call_612341: Call_DisassociatePhoneNumbersFromVoiceConnector_612327;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612342 = newJObject()
  var query_612343 = newJObject()
  var body_612344 = newJObject()
  add(query_612343, "operation", newJString(operation))
  add(path_612342, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612344 = body
  result = call_612341.call(path_612342, query_612343, nil, nil, body_612344)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_612327(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_612328,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_612329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_612345 = ref object of OpenApiRestCall_610658
proc url_DisassociatePhoneNumbersFromVoiceConnectorGroup_612347(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_612346(
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
  var valid_612348 = path.getOrDefault("voiceConnectorGroupId")
  valid_612348 = validateParameter(valid_612348, JString, required = true,
                                 default = nil)
  if valid_612348 != nil:
    section.add "voiceConnectorGroupId", valid_612348
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612349 = query.getOrDefault("operation")
  valid_612349 = validateParameter(valid_612349, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_612349 != nil:
    section.add "operation", valid_612349
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
  var valid_612350 = header.getOrDefault("X-Amz-Signature")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Signature", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Content-Sha256", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-Date")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Date", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Credential")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Credential", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-Security-Token")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-Security-Token", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-Algorithm")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-Algorithm", valid_612355
  var valid_612356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "X-Amz-SignedHeaders", valid_612356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612358: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_612345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_612358.validator(path, query, header, formData, body)
  let scheme = call_612358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612358.url(scheme.get, call_612358.host, call_612358.base,
                         call_612358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612358, url, valid)

proc call*(call_612359: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_612345;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnectorGroup
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_612360 = newJObject()
  var query_612361 = newJObject()
  var body_612362 = newJObject()
  add(path_612360, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_612361, "operation", newJString(operation))
  if body != nil:
    body_612362 = body
  result = call_612359.call(path_612360, query_612361, nil, nil, body_612362)

var disassociatePhoneNumbersFromVoiceConnectorGroup* = Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_612345(
    name: "disassociatePhoneNumbersFromVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_612346,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnectorGroup_612347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSigninDelegateGroupsFromAccount_612363 = ref object of OpenApiRestCall_610658
proc url_DisassociateSigninDelegateGroupsFromAccount_612365(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateSigninDelegateGroupsFromAccount_612364(path: JsonNode;
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
  var valid_612366 = path.getOrDefault("accountId")
  valid_612366 = validateParameter(valid_612366, JString, required = true,
                                 default = nil)
  if valid_612366 != nil:
    section.add "accountId", valid_612366
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612367 = query.getOrDefault("operation")
  valid_612367 = validateParameter(valid_612367, JString, required = true, default = newJString(
      "disassociate-signin-delegate-groups"))
  if valid_612367 != nil:
    section.add "operation", valid_612367
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
  var valid_612368 = header.getOrDefault("X-Amz-Signature")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-Signature", valid_612368
  var valid_612369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-Content-Sha256", valid_612369
  var valid_612370 = header.getOrDefault("X-Amz-Date")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Date", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Credential")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Credential", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Security-Token")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Security-Token", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-Algorithm")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-Algorithm", valid_612373
  var valid_612374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-SignedHeaders", valid_612374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612376: Call_DisassociateSigninDelegateGroupsFromAccount_612363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ## 
  let valid = call_612376.validator(path, query, header, formData, body)
  let scheme = call_612376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612376.url(scheme.get, call_612376.host, call_612376.base,
                         call_612376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612376, url, valid)

proc call*(call_612377: Call_DisassociateSigninDelegateGroupsFromAccount_612363;
          body: JsonNode; accountId: string;
          operation: string = "disassociate-signin-delegate-groups"): Recallable =
  ## disassociateSigninDelegateGroupsFromAccount
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612378 = newJObject()
  var query_612379 = newJObject()
  var body_612380 = newJObject()
  add(query_612379, "operation", newJString(operation))
  if body != nil:
    body_612380 = body
  add(path_612378, "accountId", newJString(accountId))
  result = call_612377.call(path_612378, query_612379, nil, nil, body_612380)

var disassociateSigninDelegateGroupsFromAccount* = Call_DisassociateSigninDelegateGroupsFromAccount_612363(
    name: "disassociateSigninDelegateGroupsFromAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts/{accountId}#operation=disassociate-signin-delegate-groups",
    validator: validate_DisassociateSigninDelegateGroupsFromAccount_612364,
    base: "/", url: url_DisassociateSigninDelegateGroupsFromAccount_612365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_612395 = ref object of OpenApiRestCall_610658
proc url_UpdateAccountSettings_612397(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAccountSettings_612396(path: JsonNode; query: JsonNode;
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
  var valid_612398 = path.getOrDefault("accountId")
  valid_612398 = validateParameter(valid_612398, JString, required = true,
                                 default = nil)
  if valid_612398 != nil:
    section.add "accountId", valid_612398
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
  var valid_612399 = header.getOrDefault("X-Amz-Signature")
  valid_612399 = validateParameter(valid_612399, JString, required = false,
                                 default = nil)
  if valid_612399 != nil:
    section.add "X-Amz-Signature", valid_612399
  var valid_612400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "X-Amz-Content-Sha256", valid_612400
  var valid_612401 = header.getOrDefault("X-Amz-Date")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "X-Amz-Date", valid_612401
  var valid_612402 = header.getOrDefault("X-Amz-Credential")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "X-Amz-Credential", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-Security-Token")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-Security-Token", valid_612403
  var valid_612404 = header.getOrDefault("X-Amz-Algorithm")
  valid_612404 = validateParameter(valid_612404, JString, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "X-Amz-Algorithm", valid_612404
  var valid_612405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-SignedHeaders", valid_612405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612407: Call_UpdateAccountSettings_612395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_612407.validator(path, query, header, formData, body)
  let scheme = call_612407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612407.url(scheme.get, call_612407.host, call_612407.base,
                         call_612407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612407, url, valid)

proc call*(call_612408: Call_UpdateAccountSettings_612395; body: JsonNode;
          accountId: string): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612409 = newJObject()
  var body_612410 = newJObject()
  if body != nil:
    body_612410 = body
  add(path_612409, "accountId", newJString(accountId))
  result = call_612408.call(path_612409, nil, nil, nil, body_612410)

var updateAccountSettings* = Call_UpdateAccountSettings_612395(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_612396, base: "/",
    url: url_UpdateAccountSettings_612397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_612381 = ref object of OpenApiRestCall_610658
proc url_GetAccountSettings_612383(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccountSettings_612382(path: JsonNode; query: JsonNode;
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
  var valid_612384 = path.getOrDefault("accountId")
  valid_612384 = validateParameter(valid_612384, JString, required = true,
                                 default = nil)
  if valid_612384 != nil:
    section.add "accountId", valid_612384
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
  var valid_612385 = header.getOrDefault("X-Amz-Signature")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-Signature", valid_612385
  var valid_612386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "X-Amz-Content-Sha256", valid_612386
  var valid_612387 = header.getOrDefault("X-Amz-Date")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "X-Amz-Date", valid_612387
  var valid_612388 = header.getOrDefault("X-Amz-Credential")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Credential", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-Security-Token")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-Security-Token", valid_612389
  var valid_612390 = header.getOrDefault("X-Amz-Algorithm")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Algorithm", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-SignedHeaders", valid_612391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612392: Call_GetAccountSettings_612381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_612392.validator(path, query, header, formData, body)
  let scheme = call_612392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612392.url(scheme.get, call_612392.host, call_612392.base,
                         call_612392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612392, url, valid)

proc call*(call_612393: Call_GetAccountSettings_612381; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612394 = newJObject()
  add(path_612394, "accountId", newJString(accountId))
  result = call_612393.call(path_612394, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_612381(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_612382, base: "/",
    url: url_GetAccountSettings_612383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_612426 = ref object of OpenApiRestCall_610658
proc url_UpdateBot_612428(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBot_612427(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612429 = path.getOrDefault("botId")
  valid_612429 = validateParameter(valid_612429, JString, required = true,
                                 default = nil)
  if valid_612429 != nil:
    section.add "botId", valid_612429
  var valid_612430 = path.getOrDefault("accountId")
  valid_612430 = validateParameter(valid_612430, JString, required = true,
                                 default = nil)
  if valid_612430 != nil:
    section.add "accountId", valid_612430
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
  var valid_612431 = header.getOrDefault("X-Amz-Signature")
  valid_612431 = validateParameter(valid_612431, JString, required = false,
                                 default = nil)
  if valid_612431 != nil:
    section.add "X-Amz-Signature", valid_612431
  var valid_612432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612432 = validateParameter(valid_612432, JString, required = false,
                                 default = nil)
  if valid_612432 != nil:
    section.add "X-Amz-Content-Sha256", valid_612432
  var valid_612433 = header.getOrDefault("X-Amz-Date")
  valid_612433 = validateParameter(valid_612433, JString, required = false,
                                 default = nil)
  if valid_612433 != nil:
    section.add "X-Amz-Date", valid_612433
  var valid_612434 = header.getOrDefault("X-Amz-Credential")
  valid_612434 = validateParameter(valid_612434, JString, required = false,
                                 default = nil)
  if valid_612434 != nil:
    section.add "X-Amz-Credential", valid_612434
  var valid_612435 = header.getOrDefault("X-Amz-Security-Token")
  valid_612435 = validateParameter(valid_612435, JString, required = false,
                                 default = nil)
  if valid_612435 != nil:
    section.add "X-Amz-Security-Token", valid_612435
  var valid_612436 = header.getOrDefault("X-Amz-Algorithm")
  valid_612436 = validateParameter(valid_612436, JString, required = false,
                                 default = nil)
  if valid_612436 != nil:
    section.add "X-Amz-Algorithm", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-SignedHeaders", valid_612437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612439: Call_UpdateBot_612426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_612439.validator(path, query, header, formData, body)
  let scheme = call_612439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612439.url(scheme.get, call_612439.host, call_612439.base,
                         call_612439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612439, url, valid)

proc call*(call_612440: Call_UpdateBot_612426; botId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612441 = newJObject()
  var body_612442 = newJObject()
  add(path_612441, "botId", newJString(botId))
  if body != nil:
    body_612442 = body
  add(path_612441, "accountId", newJString(accountId))
  result = call_612440.call(path_612441, nil, nil, nil, body_612442)

var updateBot* = Call_UpdateBot_612426(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_612427,
                                    base: "/", url: url_UpdateBot_612428,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_612411 = ref object of OpenApiRestCall_610658
proc url_GetBot_612413(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBot_612412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612414 = path.getOrDefault("botId")
  valid_612414 = validateParameter(valid_612414, JString, required = true,
                                 default = nil)
  if valid_612414 != nil:
    section.add "botId", valid_612414
  var valid_612415 = path.getOrDefault("accountId")
  valid_612415 = validateParameter(valid_612415, JString, required = true,
                                 default = nil)
  if valid_612415 != nil:
    section.add "accountId", valid_612415
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
  var valid_612416 = header.getOrDefault("X-Amz-Signature")
  valid_612416 = validateParameter(valid_612416, JString, required = false,
                                 default = nil)
  if valid_612416 != nil:
    section.add "X-Amz-Signature", valid_612416
  var valid_612417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612417 = validateParameter(valid_612417, JString, required = false,
                                 default = nil)
  if valid_612417 != nil:
    section.add "X-Amz-Content-Sha256", valid_612417
  var valid_612418 = header.getOrDefault("X-Amz-Date")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Date", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-Credential")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-Credential", valid_612419
  var valid_612420 = header.getOrDefault("X-Amz-Security-Token")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Security-Token", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Algorithm")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Algorithm", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-SignedHeaders", valid_612422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612423: Call_GetBot_612411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_612423.validator(path, query, header, formData, body)
  let scheme = call_612423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612423.url(scheme.get, call_612423.host, call_612423.base,
                         call_612423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612423, url, valid)

proc call*(call_612424: Call_GetBot_612411; botId: string; accountId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612425 = newJObject()
  add(path_612425, "botId", newJString(botId))
  add(path_612425, "accountId", newJString(accountId))
  result = call_612424.call(path_612425, nil, nil, nil, nil)

var getBot* = Call_GetBot_612411(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_612412, base: "/",
                              url: url_GetBot_612413,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_612455 = ref object of OpenApiRestCall_610658
proc url_UpdateGlobalSettings_612457(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGlobalSettings_612456(path: JsonNode; query: JsonNode;
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
  var valid_612458 = header.getOrDefault("X-Amz-Signature")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-Signature", valid_612458
  var valid_612459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612459 = validateParameter(valid_612459, JString, required = false,
                                 default = nil)
  if valid_612459 != nil:
    section.add "X-Amz-Content-Sha256", valid_612459
  var valid_612460 = header.getOrDefault("X-Amz-Date")
  valid_612460 = validateParameter(valid_612460, JString, required = false,
                                 default = nil)
  if valid_612460 != nil:
    section.add "X-Amz-Date", valid_612460
  var valid_612461 = header.getOrDefault("X-Amz-Credential")
  valid_612461 = validateParameter(valid_612461, JString, required = false,
                                 default = nil)
  if valid_612461 != nil:
    section.add "X-Amz-Credential", valid_612461
  var valid_612462 = header.getOrDefault("X-Amz-Security-Token")
  valid_612462 = validateParameter(valid_612462, JString, required = false,
                                 default = nil)
  if valid_612462 != nil:
    section.add "X-Amz-Security-Token", valid_612462
  var valid_612463 = header.getOrDefault("X-Amz-Algorithm")
  valid_612463 = validateParameter(valid_612463, JString, required = false,
                                 default = nil)
  if valid_612463 != nil:
    section.add "X-Amz-Algorithm", valid_612463
  var valid_612464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612464 = validateParameter(valid_612464, JString, required = false,
                                 default = nil)
  if valid_612464 != nil:
    section.add "X-Amz-SignedHeaders", valid_612464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612466: Call_UpdateGlobalSettings_612455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_612466.validator(path, query, header, formData, body)
  let scheme = call_612466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612466.url(scheme.get, call_612466.host, call_612466.base,
                         call_612466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612466, url, valid)

proc call*(call_612467: Call_UpdateGlobalSettings_612455; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_612468 = newJObject()
  if body != nil:
    body_612468 = body
  result = call_612467.call(nil, nil, nil, nil, body_612468)

var updateGlobalSettings* = Call_UpdateGlobalSettings_612455(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_612456, base: "/",
    url: url_UpdateGlobalSettings_612457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_612443 = ref object of OpenApiRestCall_610658
proc url_GetGlobalSettings_612445(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGlobalSettings_612444(path: JsonNode; query: JsonNode;
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
  var valid_612446 = header.getOrDefault("X-Amz-Signature")
  valid_612446 = validateParameter(valid_612446, JString, required = false,
                                 default = nil)
  if valid_612446 != nil:
    section.add "X-Amz-Signature", valid_612446
  var valid_612447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612447 = validateParameter(valid_612447, JString, required = false,
                                 default = nil)
  if valid_612447 != nil:
    section.add "X-Amz-Content-Sha256", valid_612447
  var valid_612448 = header.getOrDefault("X-Amz-Date")
  valid_612448 = validateParameter(valid_612448, JString, required = false,
                                 default = nil)
  if valid_612448 != nil:
    section.add "X-Amz-Date", valid_612448
  var valid_612449 = header.getOrDefault("X-Amz-Credential")
  valid_612449 = validateParameter(valid_612449, JString, required = false,
                                 default = nil)
  if valid_612449 != nil:
    section.add "X-Amz-Credential", valid_612449
  var valid_612450 = header.getOrDefault("X-Amz-Security-Token")
  valid_612450 = validateParameter(valid_612450, JString, required = false,
                                 default = nil)
  if valid_612450 != nil:
    section.add "X-Amz-Security-Token", valid_612450
  var valid_612451 = header.getOrDefault("X-Amz-Algorithm")
  valid_612451 = validateParameter(valid_612451, JString, required = false,
                                 default = nil)
  if valid_612451 != nil:
    section.add "X-Amz-Algorithm", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-SignedHeaders", valid_612452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612453: Call_GetGlobalSettings_612443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_612453.validator(path, query, header, formData, body)
  let scheme = call_612453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612453.url(scheme.get, call_612453.host, call_612453.base,
                         call_612453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612453, url, valid)

proc call*(call_612454: Call_GetGlobalSettings_612443): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_612454.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_612443(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_612444, base: "/",
    url: url_GetGlobalSettings_612445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_612469 = ref object of OpenApiRestCall_610658
proc url_GetPhoneNumberOrder_612471(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPhoneNumberOrder_612470(path: JsonNode; query: JsonNode;
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
  var valid_612472 = path.getOrDefault("phoneNumberOrderId")
  valid_612472 = validateParameter(valid_612472, JString, required = true,
                                 default = nil)
  if valid_612472 != nil:
    section.add "phoneNumberOrderId", valid_612472
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
  var valid_612473 = header.getOrDefault("X-Amz-Signature")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Signature", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Content-Sha256", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-Date")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-Date", valid_612475
  var valid_612476 = header.getOrDefault("X-Amz-Credential")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "X-Amz-Credential", valid_612476
  var valid_612477 = header.getOrDefault("X-Amz-Security-Token")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "X-Amz-Security-Token", valid_612477
  var valid_612478 = header.getOrDefault("X-Amz-Algorithm")
  valid_612478 = validateParameter(valid_612478, JString, required = false,
                                 default = nil)
  if valid_612478 != nil:
    section.add "X-Amz-Algorithm", valid_612478
  var valid_612479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612479 = validateParameter(valid_612479, JString, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "X-Amz-SignedHeaders", valid_612479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612480: Call_GetPhoneNumberOrder_612469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_612480.validator(path, query, header, formData, body)
  let scheme = call_612480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612480.url(scheme.get, call_612480.host, call_612480.base,
                         call_612480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612480, url, valid)

proc call*(call_612481: Call_GetPhoneNumberOrder_612469; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_612482 = newJObject()
  add(path_612482, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_612481.call(path_612482, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_612469(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_612470, base: "/",
    url: url_GetPhoneNumberOrder_612471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumberSettings_612495 = ref object of OpenApiRestCall_610658
proc url_UpdatePhoneNumberSettings_612497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePhoneNumberSettings_612496(path: JsonNode; query: JsonNode;
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
  var valid_612498 = header.getOrDefault("X-Amz-Signature")
  valid_612498 = validateParameter(valid_612498, JString, required = false,
                                 default = nil)
  if valid_612498 != nil:
    section.add "X-Amz-Signature", valid_612498
  var valid_612499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "X-Amz-Content-Sha256", valid_612499
  var valid_612500 = header.getOrDefault("X-Amz-Date")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "X-Amz-Date", valid_612500
  var valid_612501 = header.getOrDefault("X-Amz-Credential")
  valid_612501 = validateParameter(valid_612501, JString, required = false,
                                 default = nil)
  if valid_612501 != nil:
    section.add "X-Amz-Credential", valid_612501
  var valid_612502 = header.getOrDefault("X-Amz-Security-Token")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "X-Amz-Security-Token", valid_612502
  var valid_612503 = header.getOrDefault("X-Amz-Algorithm")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "X-Amz-Algorithm", valid_612503
  var valid_612504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612504 = validateParameter(valid_612504, JString, required = false,
                                 default = nil)
  if valid_612504 != nil:
    section.add "X-Amz-SignedHeaders", valid_612504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612506: Call_UpdatePhoneNumberSettings_612495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ## 
  let valid = call_612506.validator(path, query, header, formData, body)
  let scheme = call_612506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612506.url(scheme.get, call_612506.host, call_612506.base,
                         call_612506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612506, url, valid)

proc call*(call_612507: Call_UpdatePhoneNumberSettings_612495; body: JsonNode): Recallable =
  ## updatePhoneNumberSettings
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ##   body: JObject (required)
  var body_612508 = newJObject()
  if body != nil:
    body_612508 = body
  result = call_612507.call(nil, nil, nil, nil, body_612508)

var updatePhoneNumberSettings* = Call_UpdatePhoneNumberSettings_612495(
    name: "updatePhoneNumberSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_UpdatePhoneNumberSettings_612496, base: "/",
    url: url_UpdatePhoneNumberSettings_612497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberSettings_612483 = ref object of OpenApiRestCall_610658
proc url_GetPhoneNumberSettings_612485(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPhoneNumberSettings_612484(path: JsonNode; query: JsonNode;
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
  var valid_612486 = header.getOrDefault("X-Amz-Signature")
  valid_612486 = validateParameter(valid_612486, JString, required = false,
                                 default = nil)
  if valid_612486 != nil:
    section.add "X-Amz-Signature", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Content-Sha256", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Date")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Date", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-Credential")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Credential", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Security-Token")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Security-Token", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-Algorithm")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Algorithm", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-SignedHeaders", valid_612492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612493: Call_GetPhoneNumberSettings_612483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  let valid = call_612493.validator(path, query, header, formData, body)
  let scheme = call_612493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612493.url(scheme.get, call_612493.host, call_612493.base,
                         call_612493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612493, url, valid)

proc call*(call_612494: Call_GetPhoneNumberSettings_612483): Recallable =
  ## getPhoneNumberSettings
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  result = call_612494.call(nil, nil, nil, nil, nil)

var getPhoneNumberSettings* = Call_GetPhoneNumberSettings_612483(
    name: "getPhoneNumberSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_GetPhoneNumberSettings_612484, base: "/",
    url: url_GetPhoneNumberSettings_612485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_612524 = ref object of OpenApiRestCall_610658
proc url_UpdateUser_612526(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_612525(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612527 = path.getOrDefault("userId")
  valid_612527 = validateParameter(valid_612527, JString, required = true,
                                 default = nil)
  if valid_612527 != nil:
    section.add "userId", valid_612527
  var valid_612528 = path.getOrDefault("accountId")
  valid_612528 = validateParameter(valid_612528, JString, required = true,
                                 default = nil)
  if valid_612528 != nil:
    section.add "accountId", valid_612528
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
  var valid_612529 = header.getOrDefault("X-Amz-Signature")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "X-Amz-Signature", valid_612529
  var valid_612530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612530 = validateParameter(valid_612530, JString, required = false,
                                 default = nil)
  if valid_612530 != nil:
    section.add "X-Amz-Content-Sha256", valid_612530
  var valid_612531 = header.getOrDefault("X-Amz-Date")
  valid_612531 = validateParameter(valid_612531, JString, required = false,
                                 default = nil)
  if valid_612531 != nil:
    section.add "X-Amz-Date", valid_612531
  var valid_612532 = header.getOrDefault("X-Amz-Credential")
  valid_612532 = validateParameter(valid_612532, JString, required = false,
                                 default = nil)
  if valid_612532 != nil:
    section.add "X-Amz-Credential", valid_612532
  var valid_612533 = header.getOrDefault("X-Amz-Security-Token")
  valid_612533 = validateParameter(valid_612533, JString, required = false,
                                 default = nil)
  if valid_612533 != nil:
    section.add "X-Amz-Security-Token", valid_612533
  var valid_612534 = header.getOrDefault("X-Amz-Algorithm")
  valid_612534 = validateParameter(valid_612534, JString, required = false,
                                 default = nil)
  if valid_612534 != nil:
    section.add "X-Amz-Algorithm", valid_612534
  var valid_612535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612535 = validateParameter(valid_612535, JString, required = false,
                                 default = nil)
  if valid_612535 != nil:
    section.add "X-Amz-SignedHeaders", valid_612535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612537: Call_UpdateUser_612524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_612537.validator(path, query, header, formData, body)
  let scheme = call_612537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612537.url(scheme.get, call_612537.host, call_612537.base,
                         call_612537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612537, url, valid)

proc call*(call_612538: Call_UpdateUser_612524; userId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612539 = newJObject()
  var body_612540 = newJObject()
  add(path_612539, "userId", newJString(userId))
  if body != nil:
    body_612540 = body
  add(path_612539, "accountId", newJString(accountId))
  result = call_612538.call(path_612539, nil, nil, nil, body_612540)

var updateUser* = Call_UpdateUser_612524(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_612525,
                                      base: "/", url: url_UpdateUser_612526,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_612509 = ref object of OpenApiRestCall_610658
proc url_GetUser_612511(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUser_612510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612512 = path.getOrDefault("userId")
  valid_612512 = validateParameter(valid_612512, JString, required = true,
                                 default = nil)
  if valid_612512 != nil:
    section.add "userId", valid_612512
  var valid_612513 = path.getOrDefault("accountId")
  valid_612513 = validateParameter(valid_612513, JString, required = true,
                                 default = nil)
  if valid_612513 != nil:
    section.add "accountId", valid_612513
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
  var valid_612514 = header.getOrDefault("X-Amz-Signature")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "X-Amz-Signature", valid_612514
  var valid_612515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "X-Amz-Content-Sha256", valid_612515
  var valid_612516 = header.getOrDefault("X-Amz-Date")
  valid_612516 = validateParameter(valid_612516, JString, required = false,
                                 default = nil)
  if valid_612516 != nil:
    section.add "X-Amz-Date", valid_612516
  var valid_612517 = header.getOrDefault("X-Amz-Credential")
  valid_612517 = validateParameter(valid_612517, JString, required = false,
                                 default = nil)
  if valid_612517 != nil:
    section.add "X-Amz-Credential", valid_612517
  var valid_612518 = header.getOrDefault("X-Amz-Security-Token")
  valid_612518 = validateParameter(valid_612518, JString, required = false,
                                 default = nil)
  if valid_612518 != nil:
    section.add "X-Amz-Security-Token", valid_612518
  var valid_612519 = header.getOrDefault("X-Amz-Algorithm")
  valid_612519 = validateParameter(valid_612519, JString, required = false,
                                 default = nil)
  if valid_612519 != nil:
    section.add "X-Amz-Algorithm", valid_612519
  var valid_612520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612520 = validateParameter(valid_612520, JString, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "X-Amz-SignedHeaders", valid_612520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612521: Call_GetUser_612509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_612521.validator(path, query, header, formData, body)
  let scheme = call_612521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612521.url(scheme.get, call_612521.host, call_612521.base,
                         call_612521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612521, url, valid)

proc call*(call_612522: Call_GetUser_612509; userId: string; accountId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612523 = newJObject()
  add(path_612523, "userId", newJString(userId))
  add(path_612523, "accountId", newJString(accountId))
  result = call_612522.call(path_612523, nil, nil, nil, nil)

var getUser* = Call_GetUser_612509(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_612510, base: "/",
                                url: url_GetUser_612511,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_612556 = ref object of OpenApiRestCall_610658
proc url_UpdateUserSettings_612558(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserSettings_612557(path: JsonNode; query: JsonNode;
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
  var valid_612559 = path.getOrDefault("userId")
  valid_612559 = validateParameter(valid_612559, JString, required = true,
                                 default = nil)
  if valid_612559 != nil:
    section.add "userId", valid_612559
  var valid_612560 = path.getOrDefault("accountId")
  valid_612560 = validateParameter(valid_612560, JString, required = true,
                                 default = nil)
  if valid_612560 != nil:
    section.add "accountId", valid_612560
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
  var valid_612561 = header.getOrDefault("X-Amz-Signature")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "X-Amz-Signature", valid_612561
  var valid_612562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "X-Amz-Content-Sha256", valid_612562
  var valid_612563 = header.getOrDefault("X-Amz-Date")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "X-Amz-Date", valid_612563
  var valid_612564 = header.getOrDefault("X-Amz-Credential")
  valid_612564 = validateParameter(valid_612564, JString, required = false,
                                 default = nil)
  if valid_612564 != nil:
    section.add "X-Amz-Credential", valid_612564
  var valid_612565 = header.getOrDefault("X-Amz-Security-Token")
  valid_612565 = validateParameter(valid_612565, JString, required = false,
                                 default = nil)
  if valid_612565 != nil:
    section.add "X-Amz-Security-Token", valid_612565
  var valid_612566 = header.getOrDefault("X-Amz-Algorithm")
  valid_612566 = validateParameter(valid_612566, JString, required = false,
                                 default = nil)
  if valid_612566 != nil:
    section.add "X-Amz-Algorithm", valid_612566
  var valid_612567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612567 = validateParameter(valid_612567, JString, required = false,
                                 default = nil)
  if valid_612567 != nil:
    section.add "X-Amz-SignedHeaders", valid_612567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612569: Call_UpdateUserSettings_612556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_612569.validator(path, query, header, formData, body)
  let scheme = call_612569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612569.url(scheme.get, call_612569.host, call_612569.base,
                         call_612569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612569, url, valid)

proc call*(call_612570: Call_UpdateUserSettings_612556; userId: string;
          body: JsonNode; accountId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612571 = newJObject()
  var body_612572 = newJObject()
  add(path_612571, "userId", newJString(userId))
  if body != nil:
    body_612572 = body
  add(path_612571, "accountId", newJString(accountId))
  result = call_612570.call(path_612571, nil, nil, nil, body_612572)

var updateUserSettings* = Call_UpdateUserSettings_612556(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_612557, base: "/",
    url: url_UpdateUserSettings_612558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_612541 = ref object of OpenApiRestCall_610658
proc url_GetUserSettings_612543(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUserSettings_612542(path: JsonNode; query: JsonNode;
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
  var valid_612544 = path.getOrDefault("userId")
  valid_612544 = validateParameter(valid_612544, JString, required = true,
                                 default = nil)
  if valid_612544 != nil:
    section.add "userId", valid_612544
  var valid_612545 = path.getOrDefault("accountId")
  valid_612545 = validateParameter(valid_612545, JString, required = true,
                                 default = nil)
  if valid_612545 != nil:
    section.add "accountId", valid_612545
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
  var valid_612546 = header.getOrDefault("X-Amz-Signature")
  valid_612546 = validateParameter(valid_612546, JString, required = false,
                                 default = nil)
  if valid_612546 != nil:
    section.add "X-Amz-Signature", valid_612546
  var valid_612547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612547 = validateParameter(valid_612547, JString, required = false,
                                 default = nil)
  if valid_612547 != nil:
    section.add "X-Amz-Content-Sha256", valid_612547
  var valid_612548 = header.getOrDefault("X-Amz-Date")
  valid_612548 = validateParameter(valid_612548, JString, required = false,
                                 default = nil)
  if valid_612548 != nil:
    section.add "X-Amz-Date", valid_612548
  var valid_612549 = header.getOrDefault("X-Amz-Credential")
  valid_612549 = validateParameter(valid_612549, JString, required = false,
                                 default = nil)
  if valid_612549 != nil:
    section.add "X-Amz-Credential", valid_612549
  var valid_612550 = header.getOrDefault("X-Amz-Security-Token")
  valid_612550 = validateParameter(valid_612550, JString, required = false,
                                 default = nil)
  if valid_612550 != nil:
    section.add "X-Amz-Security-Token", valid_612550
  var valid_612551 = header.getOrDefault("X-Amz-Algorithm")
  valid_612551 = validateParameter(valid_612551, JString, required = false,
                                 default = nil)
  if valid_612551 != nil:
    section.add "X-Amz-Algorithm", valid_612551
  var valid_612552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612552 = validateParameter(valid_612552, JString, required = false,
                                 default = nil)
  if valid_612552 != nil:
    section.add "X-Amz-SignedHeaders", valid_612552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612553: Call_GetUserSettings_612541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_612553.validator(path, query, header, formData, body)
  let scheme = call_612553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612553.url(scheme.get, call_612553.host, call_612553.base,
                         call_612553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612553, url, valid)

proc call*(call_612554: Call_GetUserSettings_612541; userId: string;
          accountId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612555 = newJObject()
  add(path_612555, "userId", newJString(userId))
  add(path_612555, "accountId", newJString(accountId))
  result = call_612554.call(path_612555, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_612541(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_612542, base: "/", url: url_GetUserSettings_612543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorLoggingConfiguration_612587 = ref object of OpenApiRestCall_610658
proc url_PutVoiceConnectorLoggingConfiguration_612589(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorLoggingConfiguration_612588(path: JsonNode;
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
  var valid_612590 = path.getOrDefault("voiceConnectorId")
  valid_612590 = validateParameter(valid_612590, JString, required = true,
                                 default = nil)
  if valid_612590 != nil:
    section.add "voiceConnectorId", valid_612590
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
  var valid_612591 = header.getOrDefault("X-Amz-Signature")
  valid_612591 = validateParameter(valid_612591, JString, required = false,
                                 default = nil)
  if valid_612591 != nil:
    section.add "X-Amz-Signature", valid_612591
  var valid_612592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612592 = validateParameter(valid_612592, JString, required = false,
                                 default = nil)
  if valid_612592 != nil:
    section.add "X-Amz-Content-Sha256", valid_612592
  var valid_612593 = header.getOrDefault("X-Amz-Date")
  valid_612593 = validateParameter(valid_612593, JString, required = false,
                                 default = nil)
  if valid_612593 != nil:
    section.add "X-Amz-Date", valid_612593
  var valid_612594 = header.getOrDefault("X-Amz-Credential")
  valid_612594 = validateParameter(valid_612594, JString, required = false,
                                 default = nil)
  if valid_612594 != nil:
    section.add "X-Amz-Credential", valid_612594
  var valid_612595 = header.getOrDefault("X-Amz-Security-Token")
  valid_612595 = validateParameter(valid_612595, JString, required = false,
                                 default = nil)
  if valid_612595 != nil:
    section.add "X-Amz-Security-Token", valid_612595
  var valid_612596 = header.getOrDefault("X-Amz-Algorithm")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "X-Amz-Algorithm", valid_612596
  var valid_612597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612597 = validateParameter(valid_612597, JString, required = false,
                                 default = nil)
  if valid_612597 != nil:
    section.add "X-Amz-SignedHeaders", valid_612597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612599: Call_PutVoiceConnectorLoggingConfiguration_612587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_612599.validator(path, query, header, formData, body)
  let scheme = call_612599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612599.url(scheme.get, call_612599.host, call_612599.base,
                         call_612599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612599, url, valid)

proc call*(call_612600: Call_PutVoiceConnectorLoggingConfiguration_612587;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorLoggingConfiguration
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612601 = newJObject()
  var body_612602 = newJObject()
  add(path_612601, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612602 = body
  result = call_612600.call(path_612601, nil, nil, nil, body_612602)

var putVoiceConnectorLoggingConfiguration* = Call_PutVoiceConnectorLoggingConfiguration_612587(
    name: "putVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_PutVoiceConnectorLoggingConfiguration_612588, base: "/",
    url: url_PutVoiceConnectorLoggingConfiguration_612589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorLoggingConfiguration_612573 = ref object of OpenApiRestCall_610658
proc url_GetVoiceConnectorLoggingConfiguration_612575(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorLoggingConfiguration_612574(path: JsonNode;
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
  var valid_612576 = path.getOrDefault("voiceConnectorId")
  valid_612576 = validateParameter(valid_612576, JString, required = true,
                                 default = nil)
  if valid_612576 != nil:
    section.add "voiceConnectorId", valid_612576
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
  var valid_612577 = header.getOrDefault("X-Amz-Signature")
  valid_612577 = validateParameter(valid_612577, JString, required = false,
                                 default = nil)
  if valid_612577 != nil:
    section.add "X-Amz-Signature", valid_612577
  var valid_612578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612578 = validateParameter(valid_612578, JString, required = false,
                                 default = nil)
  if valid_612578 != nil:
    section.add "X-Amz-Content-Sha256", valid_612578
  var valid_612579 = header.getOrDefault("X-Amz-Date")
  valid_612579 = validateParameter(valid_612579, JString, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "X-Amz-Date", valid_612579
  var valid_612580 = header.getOrDefault("X-Amz-Credential")
  valid_612580 = validateParameter(valid_612580, JString, required = false,
                                 default = nil)
  if valid_612580 != nil:
    section.add "X-Amz-Credential", valid_612580
  var valid_612581 = header.getOrDefault("X-Amz-Security-Token")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Security-Token", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-Algorithm")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-Algorithm", valid_612582
  var valid_612583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "X-Amz-SignedHeaders", valid_612583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612584: Call_GetVoiceConnectorLoggingConfiguration_612573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_612584.validator(path, query, header, formData, body)
  let scheme = call_612584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612584.url(scheme.get, call_612584.host, call_612584.base,
                         call_612584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612584, url, valid)

proc call*(call_612585: Call_GetVoiceConnectorLoggingConfiguration_612573;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorLoggingConfiguration
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612586 = newJObject()
  add(path_612586, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612585.call(path_612586, nil, nil, nil, nil)

var getVoiceConnectorLoggingConfiguration* = Call_GetVoiceConnectorLoggingConfiguration_612573(
    name: "getVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_GetVoiceConnectorLoggingConfiguration_612574, base: "/",
    url: url_GetVoiceConnectorLoggingConfiguration_612575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_612603 = ref object of OpenApiRestCall_610658
proc url_GetVoiceConnectorTerminationHealth_612605(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorTerminationHealth_612604(path: JsonNode;
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
  var valid_612606 = path.getOrDefault("voiceConnectorId")
  valid_612606 = validateParameter(valid_612606, JString, required = true,
                                 default = nil)
  if valid_612606 != nil:
    section.add "voiceConnectorId", valid_612606
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
  var valid_612607 = header.getOrDefault("X-Amz-Signature")
  valid_612607 = validateParameter(valid_612607, JString, required = false,
                                 default = nil)
  if valid_612607 != nil:
    section.add "X-Amz-Signature", valid_612607
  var valid_612608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612608 = validateParameter(valid_612608, JString, required = false,
                                 default = nil)
  if valid_612608 != nil:
    section.add "X-Amz-Content-Sha256", valid_612608
  var valid_612609 = header.getOrDefault("X-Amz-Date")
  valid_612609 = validateParameter(valid_612609, JString, required = false,
                                 default = nil)
  if valid_612609 != nil:
    section.add "X-Amz-Date", valid_612609
  var valid_612610 = header.getOrDefault("X-Amz-Credential")
  valid_612610 = validateParameter(valid_612610, JString, required = false,
                                 default = nil)
  if valid_612610 != nil:
    section.add "X-Amz-Credential", valid_612610
  var valid_612611 = header.getOrDefault("X-Amz-Security-Token")
  valid_612611 = validateParameter(valid_612611, JString, required = false,
                                 default = nil)
  if valid_612611 != nil:
    section.add "X-Amz-Security-Token", valid_612611
  var valid_612612 = header.getOrDefault("X-Amz-Algorithm")
  valid_612612 = validateParameter(valid_612612, JString, required = false,
                                 default = nil)
  if valid_612612 != nil:
    section.add "X-Amz-Algorithm", valid_612612
  var valid_612613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612613 = validateParameter(valid_612613, JString, required = false,
                                 default = nil)
  if valid_612613 != nil:
    section.add "X-Amz-SignedHeaders", valid_612613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612614: Call_GetVoiceConnectorTerminationHealth_612603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612614.validator(path, query, header, formData, body)
  let scheme = call_612614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612614.url(scheme.get, call_612614.host, call_612614.base,
                         call_612614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612614, url, valid)

proc call*(call_612615: Call_GetVoiceConnectorTerminationHealth_612603;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612616 = newJObject()
  add(path_612616, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612615.call(path_612616, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_612603(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_612604, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_612605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_612617 = ref object of OpenApiRestCall_610658
proc url_InviteUsers_612619(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InviteUsers_612618(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612620 = path.getOrDefault("accountId")
  valid_612620 = validateParameter(valid_612620, JString, required = true,
                                 default = nil)
  if valid_612620 != nil:
    section.add "accountId", valid_612620
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612621 = query.getOrDefault("operation")
  valid_612621 = validateParameter(valid_612621, JString, required = true,
                                 default = newJString("add"))
  if valid_612621 != nil:
    section.add "operation", valid_612621
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
  var valid_612622 = header.getOrDefault("X-Amz-Signature")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-Signature", valid_612622
  var valid_612623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "X-Amz-Content-Sha256", valid_612623
  var valid_612624 = header.getOrDefault("X-Amz-Date")
  valid_612624 = validateParameter(valid_612624, JString, required = false,
                                 default = nil)
  if valid_612624 != nil:
    section.add "X-Amz-Date", valid_612624
  var valid_612625 = header.getOrDefault("X-Amz-Credential")
  valid_612625 = validateParameter(valid_612625, JString, required = false,
                                 default = nil)
  if valid_612625 != nil:
    section.add "X-Amz-Credential", valid_612625
  var valid_612626 = header.getOrDefault("X-Amz-Security-Token")
  valid_612626 = validateParameter(valid_612626, JString, required = false,
                                 default = nil)
  if valid_612626 != nil:
    section.add "X-Amz-Security-Token", valid_612626
  var valid_612627 = header.getOrDefault("X-Amz-Algorithm")
  valid_612627 = validateParameter(valid_612627, JString, required = false,
                                 default = nil)
  if valid_612627 != nil:
    section.add "X-Amz-Algorithm", valid_612627
  var valid_612628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612628 = validateParameter(valid_612628, JString, required = false,
                                 default = nil)
  if valid_612628 != nil:
    section.add "X-Amz-SignedHeaders", valid_612628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612630: Call_InviteUsers_612617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_612630.validator(path, query, header, formData, body)
  let scheme = call_612630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612630.url(scheme.get, call_612630.host, call_612630.base,
                         call_612630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612630, url, valid)

proc call*(call_612631: Call_InviteUsers_612617; body: JsonNode; accountId: string;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612632 = newJObject()
  var query_612633 = newJObject()
  var body_612634 = newJObject()
  add(query_612633, "operation", newJString(operation))
  if body != nil:
    body_612634 = body
  add(path_612632, "accountId", newJString(accountId))
  result = call_612631.call(path_612632, query_612633, nil, nil, body_612634)

var inviteUsers* = Call_InviteUsers_612617(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_612618,
                                        base: "/", url: url_InviteUsers_612619,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_612635 = ref object of OpenApiRestCall_610658
proc url_ListPhoneNumbers_612637(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumbers_612636(path: JsonNode; query: JsonNode;
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
  var valid_612638 = query.getOrDefault("MaxResults")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "MaxResults", valid_612638
  var valid_612639 = query.getOrDefault("NextToken")
  valid_612639 = validateParameter(valid_612639, JString, required = false,
                                 default = nil)
  if valid_612639 != nil:
    section.add "NextToken", valid_612639
  var valid_612640 = query.getOrDefault("product-type")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_612640 != nil:
    section.add "product-type", valid_612640
  var valid_612641 = query.getOrDefault("filter-name")
  valid_612641 = validateParameter(valid_612641, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_612641 != nil:
    section.add "filter-name", valid_612641
  var valid_612642 = query.getOrDefault("max-results")
  valid_612642 = validateParameter(valid_612642, JInt, required = false, default = nil)
  if valid_612642 != nil:
    section.add "max-results", valid_612642
  var valid_612643 = query.getOrDefault("status")
  valid_612643 = validateParameter(valid_612643, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_612643 != nil:
    section.add "status", valid_612643
  var valid_612644 = query.getOrDefault("filter-value")
  valid_612644 = validateParameter(valid_612644, JString, required = false,
                                 default = nil)
  if valid_612644 != nil:
    section.add "filter-value", valid_612644
  var valid_612645 = query.getOrDefault("next-token")
  valid_612645 = validateParameter(valid_612645, JString, required = false,
                                 default = nil)
  if valid_612645 != nil:
    section.add "next-token", valid_612645
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
  var valid_612646 = header.getOrDefault("X-Amz-Signature")
  valid_612646 = validateParameter(valid_612646, JString, required = false,
                                 default = nil)
  if valid_612646 != nil:
    section.add "X-Amz-Signature", valid_612646
  var valid_612647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "X-Amz-Content-Sha256", valid_612647
  var valid_612648 = header.getOrDefault("X-Amz-Date")
  valid_612648 = validateParameter(valid_612648, JString, required = false,
                                 default = nil)
  if valid_612648 != nil:
    section.add "X-Amz-Date", valid_612648
  var valid_612649 = header.getOrDefault("X-Amz-Credential")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "X-Amz-Credential", valid_612649
  var valid_612650 = header.getOrDefault("X-Amz-Security-Token")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "X-Amz-Security-Token", valid_612650
  var valid_612651 = header.getOrDefault("X-Amz-Algorithm")
  valid_612651 = validateParameter(valid_612651, JString, required = false,
                                 default = nil)
  if valid_612651 != nil:
    section.add "X-Amz-Algorithm", valid_612651
  var valid_612652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "X-Amz-SignedHeaders", valid_612652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612653: Call_ListPhoneNumbers_612635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  let valid = call_612653.validator(path, query, header, formData, body)
  let scheme = call_612653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612653.url(scheme.get, call_612653.host, call_612653.base,
                         call_612653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612653, url, valid)

proc call*(call_612654: Call_ListPhoneNumbers_612635; MaxResults: string = "";
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
  var query_612655 = newJObject()
  add(query_612655, "MaxResults", newJString(MaxResults))
  add(query_612655, "NextToken", newJString(NextToken))
  add(query_612655, "product-type", newJString(productType))
  add(query_612655, "filter-name", newJString(filterName))
  add(query_612655, "max-results", newJInt(maxResults))
  add(query_612655, "status", newJString(status))
  add(query_612655, "filter-value", newJString(filterValue))
  add(query_612655, "next-token", newJString(nextToken))
  result = call_612654.call(nil, query_612655, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_612635(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_612636, base: "/",
    url: url_ListPhoneNumbers_612637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_612656 = ref object of OpenApiRestCall_610658
proc url_ListVoiceConnectorTerminationCredentials_612658(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVoiceConnectorTerminationCredentials_612657(path: JsonNode;
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
  var valid_612659 = path.getOrDefault("voiceConnectorId")
  valid_612659 = validateParameter(valid_612659, JString, required = true,
                                 default = nil)
  if valid_612659 != nil:
    section.add "voiceConnectorId", valid_612659
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
  var valid_612660 = header.getOrDefault("X-Amz-Signature")
  valid_612660 = validateParameter(valid_612660, JString, required = false,
                                 default = nil)
  if valid_612660 != nil:
    section.add "X-Amz-Signature", valid_612660
  var valid_612661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "X-Amz-Content-Sha256", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-Date")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-Date", valid_612662
  var valid_612663 = header.getOrDefault("X-Amz-Credential")
  valid_612663 = validateParameter(valid_612663, JString, required = false,
                                 default = nil)
  if valid_612663 != nil:
    section.add "X-Amz-Credential", valid_612663
  var valid_612664 = header.getOrDefault("X-Amz-Security-Token")
  valid_612664 = validateParameter(valid_612664, JString, required = false,
                                 default = nil)
  if valid_612664 != nil:
    section.add "X-Amz-Security-Token", valid_612664
  var valid_612665 = header.getOrDefault("X-Amz-Algorithm")
  valid_612665 = validateParameter(valid_612665, JString, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "X-Amz-Algorithm", valid_612665
  var valid_612666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612666 = validateParameter(valid_612666, JString, required = false,
                                 default = nil)
  if valid_612666 != nil:
    section.add "X-Amz-SignedHeaders", valid_612666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612667: Call_ListVoiceConnectorTerminationCredentials_612656;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612667.validator(path, query, header, formData, body)
  let scheme = call_612667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612667.url(scheme.get, call_612667.host, call_612667.base,
                         call_612667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612667, url, valid)

proc call*(call_612668: Call_ListVoiceConnectorTerminationCredentials_612656;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_612669 = newJObject()
  add(path_612669, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_612668.call(path_612669, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_612656(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_612657,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_612658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_612670 = ref object of OpenApiRestCall_610658
proc url_LogoutUser_612672(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_LogoutUser_612671(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612673 = path.getOrDefault("userId")
  valid_612673 = validateParameter(valid_612673, JString, required = true,
                                 default = nil)
  if valid_612673 != nil:
    section.add "userId", valid_612673
  var valid_612674 = path.getOrDefault("accountId")
  valid_612674 = validateParameter(valid_612674, JString, required = true,
                                 default = nil)
  if valid_612674 != nil:
    section.add "accountId", valid_612674
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612675 = query.getOrDefault("operation")
  valid_612675 = validateParameter(valid_612675, JString, required = true,
                                 default = newJString("logout"))
  if valid_612675 != nil:
    section.add "operation", valid_612675
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
  var valid_612676 = header.getOrDefault("X-Amz-Signature")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "X-Amz-Signature", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-Content-Sha256", valid_612677
  var valid_612678 = header.getOrDefault("X-Amz-Date")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-Date", valid_612678
  var valid_612679 = header.getOrDefault("X-Amz-Credential")
  valid_612679 = validateParameter(valid_612679, JString, required = false,
                                 default = nil)
  if valid_612679 != nil:
    section.add "X-Amz-Credential", valid_612679
  var valid_612680 = header.getOrDefault("X-Amz-Security-Token")
  valid_612680 = validateParameter(valid_612680, JString, required = false,
                                 default = nil)
  if valid_612680 != nil:
    section.add "X-Amz-Security-Token", valid_612680
  var valid_612681 = header.getOrDefault("X-Amz-Algorithm")
  valid_612681 = validateParameter(valid_612681, JString, required = false,
                                 default = nil)
  if valid_612681 != nil:
    section.add "X-Amz-Algorithm", valid_612681
  var valid_612682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612682 = validateParameter(valid_612682, JString, required = false,
                                 default = nil)
  if valid_612682 != nil:
    section.add "X-Amz-SignedHeaders", valid_612682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612683: Call_LogoutUser_612670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_612683.validator(path, query, header, formData, body)
  let scheme = call_612683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612683.url(scheme.get, call_612683.host, call_612683.base,
                         call_612683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612683, url, valid)

proc call*(call_612684: Call_LogoutUser_612670; userId: string; accountId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612685 = newJObject()
  var query_612686 = newJObject()
  add(query_612686, "operation", newJString(operation))
  add(path_612685, "userId", newJString(userId))
  add(path_612685, "accountId", newJString(accountId))
  result = call_612684.call(path_612685, query_612686, nil, nil, nil)

var logoutUser* = Call_LogoutUser_612670(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_612671,
                                      base: "/", url: url_LogoutUser_612672,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_612687 = ref object of OpenApiRestCall_610658
proc url_PutVoiceConnectorTerminationCredentials_612689(protocol: Scheme;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutVoiceConnectorTerminationCredentials_612688(path: JsonNode;
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
  var valid_612690 = path.getOrDefault("voiceConnectorId")
  valid_612690 = validateParameter(valid_612690, JString, required = true,
                                 default = nil)
  if valid_612690 != nil:
    section.add "voiceConnectorId", valid_612690
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612691 = query.getOrDefault("operation")
  valid_612691 = validateParameter(valid_612691, JString, required = true,
                                 default = newJString("put"))
  if valid_612691 != nil:
    section.add "operation", valid_612691
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
  var valid_612692 = header.getOrDefault("X-Amz-Signature")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-Signature", valid_612692
  var valid_612693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-Content-Sha256", valid_612693
  var valid_612694 = header.getOrDefault("X-Amz-Date")
  valid_612694 = validateParameter(valid_612694, JString, required = false,
                                 default = nil)
  if valid_612694 != nil:
    section.add "X-Amz-Date", valid_612694
  var valid_612695 = header.getOrDefault("X-Amz-Credential")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-Credential", valid_612695
  var valid_612696 = header.getOrDefault("X-Amz-Security-Token")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "X-Amz-Security-Token", valid_612696
  var valid_612697 = header.getOrDefault("X-Amz-Algorithm")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "X-Amz-Algorithm", valid_612697
  var valid_612698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "X-Amz-SignedHeaders", valid_612698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612700: Call_PutVoiceConnectorTerminationCredentials_612687;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_612700.validator(path, query, header, formData, body)
  let scheme = call_612700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612700.url(scheme.get, call_612700.host, call_612700.base,
                         call_612700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612700, url, valid)

proc call*(call_612701: Call_PutVoiceConnectorTerminationCredentials_612687;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_612702 = newJObject()
  var query_612703 = newJObject()
  var body_612704 = newJObject()
  add(query_612703, "operation", newJString(operation))
  add(path_612702, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_612704 = body
  result = call_612701.call(path_612702, query_612703, nil, nil, body_612704)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_612687(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_612688, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_612689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_612705 = ref object of OpenApiRestCall_610658
proc url_RegenerateSecurityToken_612707(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegenerateSecurityToken_612706(path: JsonNode; query: JsonNode;
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
  var valid_612708 = path.getOrDefault("botId")
  valid_612708 = validateParameter(valid_612708, JString, required = true,
                                 default = nil)
  if valid_612708 != nil:
    section.add "botId", valid_612708
  var valid_612709 = path.getOrDefault("accountId")
  valid_612709 = validateParameter(valid_612709, JString, required = true,
                                 default = nil)
  if valid_612709 != nil:
    section.add "accountId", valid_612709
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612710 = query.getOrDefault("operation")
  valid_612710 = validateParameter(valid_612710, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_612710 != nil:
    section.add "operation", valid_612710
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
  var valid_612711 = header.getOrDefault("X-Amz-Signature")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "X-Amz-Signature", valid_612711
  var valid_612712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612712 = validateParameter(valid_612712, JString, required = false,
                                 default = nil)
  if valid_612712 != nil:
    section.add "X-Amz-Content-Sha256", valid_612712
  var valid_612713 = header.getOrDefault("X-Amz-Date")
  valid_612713 = validateParameter(valid_612713, JString, required = false,
                                 default = nil)
  if valid_612713 != nil:
    section.add "X-Amz-Date", valid_612713
  var valid_612714 = header.getOrDefault("X-Amz-Credential")
  valid_612714 = validateParameter(valid_612714, JString, required = false,
                                 default = nil)
  if valid_612714 != nil:
    section.add "X-Amz-Credential", valid_612714
  var valid_612715 = header.getOrDefault("X-Amz-Security-Token")
  valid_612715 = validateParameter(valid_612715, JString, required = false,
                                 default = nil)
  if valid_612715 != nil:
    section.add "X-Amz-Security-Token", valid_612715
  var valid_612716 = header.getOrDefault("X-Amz-Algorithm")
  valid_612716 = validateParameter(valid_612716, JString, required = false,
                                 default = nil)
  if valid_612716 != nil:
    section.add "X-Amz-Algorithm", valid_612716
  var valid_612717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612717 = validateParameter(valid_612717, JString, required = false,
                                 default = nil)
  if valid_612717 != nil:
    section.add "X-Amz-SignedHeaders", valid_612717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612718: Call_RegenerateSecurityToken_612705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_612718.validator(path, query, header, formData, body)
  let scheme = call_612718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612718.url(scheme.get, call_612718.host, call_612718.base,
                         call_612718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612718, url, valid)

proc call*(call_612719: Call_RegenerateSecurityToken_612705; botId: string;
          accountId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612720 = newJObject()
  var query_612721 = newJObject()
  add(path_612720, "botId", newJString(botId))
  add(query_612721, "operation", newJString(operation))
  add(path_612720, "accountId", newJString(accountId))
  result = call_612719.call(path_612720, query_612721, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_612705(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_612706, base: "/",
    url: url_RegenerateSecurityToken_612707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_612722 = ref object of OpenApiRestCall_610658
proc url_ResetPersonalPIN_612724(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ResetPersonalPIN_612723(path: JsonNode; query: JsonNode;
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
  var valid_612725 = path.getOrDefault("userId")
  valid_612725 = validateParameter(valid_612725, JString, required = true,
                                 default = nil)
  if valid_612725 != nil:
    section.add "userId", valid_612725
  var valid_612726 = path.getOrDefault("accountId")
  valid_612726 = validateParameter(valid_612726, JString, required = true,
                                 default = nil)
  if valid_612726 != nil:
    section.add "accountId", valid_612726
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612727 = query.getOrDefault("operation")
  valid_612727 = validateParameter(valid_612727, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_612727 != nil:
    section.add "operation", valid_612727
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
  var valid_612728 = header.getOrDefault("X-Amz-Signature")
  valid_612728 = validateParameter(valid_612728, JString, required = false,
                                 default = nil)
  if valid_612728 != nil:
    section.add "X-Amz-Signature", valid_612728
  var valid_612729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612729 = validateParameter(valid_612729, JString, required = false,
                                 default = nil)
  if valid_612729 != nil:
    section.add "X-Amz-Content-Sha256", valid_612729
  var valid_612730 = header.getOrDefault("X-Amz-Date")
  valid_612730 = validateParameter(valid_612730, JString, required = false,
                                 default = nil)
  if valid_612730 != nil:
    section.add "X-Amz-Date", valid_612730
  var valid_612731 = header.getOrDefault("X-Amz-Credential")
  valid_612731 = validateParameter(valid_612731, JString, required = false,
                                 default = nil)
  if valid_612731 != nil:
    section.add "X-Amz-Credential", valid_612731
  var valid_612732 = header.getOrDefault("X-Amz-Security-Token")
  valid_612732 = validateParameter(valid_612732, JString, required = false,
                                 default = nil)
  if valid_612732 != nil:
    section.add "X-Amz-Security-Token", valid_612732
  var valid_612733 = header.getOrDefault("X-Amz-Algorithm")
  valid_612733 = validateParameter(valid_612733, JString, required = false,
                                 default = nil)
  if valid_612733 != nil:
    section.add "X-Amz-Algorithm", valid_612733
  var valid_612734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612734 = validateParameter(valid_612734, JString, required = false,
                                 default = nil)
  if valid_612734 != nil:
    section.add "X-Amz-SignedHeaders", valid_612734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612735: Call_ResetPersonalPIN_612722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_612735.validator(path, query, header, formData, body)
  let scheme = call_612735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612735.url(scheme.get, call_612735.host, call_612735.base,
                         call_612735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612735, url, valid)

proc call*(call_612736: Call_ResetPersonalPIN_612722; userId: string;
          accountId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_612737 = newJObject()
  var query_612738 = newJObject()
  add(query_612738, "operation", newJString(operation))
  add(path_612737, "userId", newJString(userId))
  add(path_612737, "accountId", newJString(accountId))
  result = call_612736.call(path_612737, query_612738, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_612722(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_612723, base: "/",
    url: url_ResetPersonalPIN_612724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_612739 = ref object of OpenApiRestCall_610658
proc url_RestorePhoneNumber_612741(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RestorePhoneNumber_612740(path: JsonNode; query: JsonNode;
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
  var valid_612742 = path.getOrDefault("phoneNumberId")
  valid_612742 = validateParameter(valid_612742, JString, required = true,
                                 default = nil)
  if valid_612742 != nil:
    section.add "phoneNumberId", valid_612742
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_612743 = query.getOrDefault("operation")
  valid_612743 = validateParameter(valid_612743, JString, required = true,
                                 default = newJString("restore"))
  if valid_612743 != nil:
    section.add "operation", valid_612743
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
  var valid_612744 = header.getOrDefault("X-Amz-Signature")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "X-Amz-Signature", valid_612744
  var valid_612745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "X-Amz-Content-Sha256", valid_612745
  var valid_612746 = header.getOrDefault("X-Amz-Date")
  valid_612746 = validateParameter(valid_612746, JString, required = false,
                                 default = nil)
  if valid_612746 != nil:
    section.add "X-Amz-Date", valid_612746
  var valid_612747 = header.getOrDefault("X-Amz-Credential")
  valid_612747 = validateParameter(valid_612747, JString, required = false,
                                 default = nil)
  if valid_612747 != nil:
    section.add "X-Amz-Credential", valid_612747
  var valid_612748 = header.getOrDefault("X-Amz-Security-Token")
  valid_612748 = validateParameter(valid_612748, JString, required = false,
                                 default = nil)
  if valid_612748 != nil:
    section.add "X-Amz-Security-Token", valid_612748
  var valid_612749 = header.getOrDefault("X-Amz-Algorithm")
  valid_612749 = validateParameter(valid_612749, JString, required = false,
                                 default = nil)
  if valid_612749 != nil:
    section.add "X-Amz-Algorithm", valid_612749
  var valid_612750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612750 = validateParameter(valid_612750, JString, required = false,
                                 default = nil)
  if valid_612750 != nil:
    section.add "X-Amz-SignedHeaders", valid_612750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612751: Call_RestorePhoneNumber_612739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_612751.validator(path, query, header, formData, body)
  let scheme = call_612751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612751.url(scheme.get, call_612751.host, call_612751.base,
                         call_612751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612751, url, valid)

proc call*(call_612752: Call_RestorePhoneNumber_612739; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_612753 = newJObject()
  var query_612754 = newJObject()
  add(path_612753, "phoneNumberId", newJString(phoneNumberId))
  add(query_612754, "operation", newJString(operation))
  result = call_612752.call(path_612753, query_612754, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_612739(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_612740, base: "/",
    url: url_RestorePhoneNumber_612741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_612755 = ref object of OpenApiRestCall_610658
proc url_SearchAvailablePhoneNumbers_612757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchAvailablePhoneNumbers_612756(path: JsonNode; query: JsonNode;
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
  var valid_612758 = query.getOrDefault("state")
  valid_612758 = validateParameter(valid_612758, JString, required = false,
                                 default = nil)
  if valid_612758 != nil:
    section.add "state", valid_612758
  var valid_612759 = query.getOrDefault("area-code")
  valid_612759 = validateParameter(valid_612759, JString, required = false,
                                 default = nil)
  if valid_612759 != nil:
    section.add "area-code", valid_612759
  var valid_612760 = query.getOrDefault("toll-free-prefix")
  valid_612760 = validateParameter(valid_612760, JString, required = false,
                                 default = nil)
  if valid_612760 != nil:
    section.add "toll-free-prefix", valid_612760
  var valid_612761 = query.getOrDefault("type")
  valid_612761 = validateParameter(valid_612761, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_612761 != nil:
    section.add "type", valid_612761
  var valid_612762 = query.getOrDefault("city")
  valid_612762 = validateParameter(valid_612762, JString, required = false,
                                 default = nil)
  if valid_612762 != nil:
    section.add "city", valid_612762
  var valid_612763 = query.getOrDefault("country")
  valid_612763 = validateParameter(valid_612763, JString, required = false,
                                 default = nil)
  if valid_612763 != nil:
    section.add "country", valid_612763
  var valid_612764 = query.getOrDefault("max-results")
  valid_612764 = validateParameter(valid_612764, JInt, required = false, default = nil)
  if valid_612764 != nil:
    section.add "max-results", valid_612764
  var valid_612765 = query.getOrDefault("next-token")
  valid_612765 = validateParameter(valid_612765, JString, required = false,
                                 default = nil)
  if valid_612765 != nil:
    section.add "next-token", valid_612765
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
  var valid_612766 = header.getOrDefault("X-Amz-Signature")
  valid_612766 = validateParameter(valid_612766, JString, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "X-Amz-Signature", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-Content-Sha256", valid_612767
  var valid_612768 = header.getOrDefault("X-Amz-Date")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "X-Amz-Date", valid_612768
  var valid_612769 = header.getOrDefault("X-Amz-Credential")
  valid_612769 = validateParameter(valid_612769, JString, required = false,
                                 default = nil)
  if valid_612769 != nil:
    section.add "X-Amz-Credential", valid_612769
  var valid_612770 = header.getOrDefault("X-Amz-Security-Token")
  valid_612770 = validateParameter(valid_612770, JString, required = false,
                                 default = nil)
  if valid_612770 != nil:
    section.add "X-Amz-Security-Token", valid_612770
  var valid_612771 = header.getOrDefault("X-Amz-Algorithm")
  valid_612771 = validateParameter(valid_612771, JString, required = false,
                                 default = nil)
  if valid_612771 != nil:
    section.add "X-Amz-Algorithm", valid_612771
  var valid_612772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612772 = validateParameter(valid_612772, JString, required = false,
                                 default = nil)
  if valid_612772 != nil:
    section.add "X-Amz-SignedHeaders", valid_612772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612773: Call_SearchAvailablePhoneNumbers_612755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_612773.validator(path, query, header, formData, body)
  let scheme = call_612773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612773.url(scheme.get, call_612773.host, call_612773.base,
                         call_612773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612773, url, valid)

proc call*(call_612774: Call_SearchAvailablePhoneNumbers_612755;
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
  var query_612775 = newJObject()
  add(query_612775, "state", newJString(state))
  add(query_612775, "area-code", newJString(areaCode))
  add(query_612775, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_612775, "type", newJString(`type`))
  add(query_612775, "city", newJString(city))
  add(query_612775, "country", newJString(country))
  add(query_612775, "max-results", newJInt(maxResults))
  add(query_612775, "next-token", newJString(nextToken))
  result = call_612774.call(nil, query_612775, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_612755(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_612756, base: "/",
    url: url_SearchAvailablePhoneNumbers_612757,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
