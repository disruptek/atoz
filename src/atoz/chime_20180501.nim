
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_AssociatePhoneNumberWithUser_612996 = ref object of OpenApiRestCall_612658
proc url_AssociatePhoneNumberWithUser_612998(protocol: Scheme; host: string;
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

proc validate_AssociatePhoneNumberWithUser_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("userId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "userId", valid_613124
  var valid_613125 = path.getOrDefault("accountId")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = nil)
  if valid_613125 != nil:
    section.add "accountId", valid_613125
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613139 = query.getOrDefault("operation")
  valid_613139 = validateParameter(valid_613139, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_613139 != nil:
    section.add "operation", valid_613139
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
  var valid_613140 = header.getOrDefault("X-Amz-Signature")
  valid_613140 = validateParameter(valid_613140, JString, required = false,
                                 default = nil)
  if valid_613140 != nil:
    section.add "X-Amz-Signature", valid_613140
  var valid_613141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613141 = validateParameter(valid_613141, JString, required = false,
                                 default = nil)
  if valid_613141 != nil:
    section.add "X-Amz-Content-Sha256", valid_613141
  var valid_613142 = header.getOrDefault("X-Amz-Date")
  valid_613142 = validateParameter(valid_613142, JString, required = false,
                                 default = nil)
  if valid_613142 != nil:
    section.add "X-Amz-Date", valid_613142
  var valid_613143 = header.getOrDefault("X-Amz-Credential")
  valid_613143 = validateParameter(valid_613143, JString, required = false,
                                 default = nil)
  if valid_613143 != nil:
    section.add "X-Amz-Credential", valid_613143
  var valid_613144 = header.getOrDefault("X-Amz-Security-Token")
  valid_613144 = validateParameter(valid_613144, JString, required = false,
                                 default = nil)
  if valid_613144 != nil:
    section.add "X-Amz-Security-Token", valid_613144
  var valid_613145 = header.getOrDefault("X-Amz-Algorithm")
  valid_613145 = validateParameter(valid_613145, JString, required = false,
                                 default = nil)
  if valid_613145 != nil:
    section.add "X-Amz-Algorithm", valid_613145
  var valid_613146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613146 = validateParameter(valid_613146, JString, required = false,
                                 default = nil)
  if valid_613146 != nil:
    section.add "X-Amz-SignedHeaders", valid_613146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613170: Call_AssociatePhoneNumberWithUser_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_613170.validator(path, query, header, formData, body)
  let scheme = call_613170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613170.url(scheme.get, call_613170.host, call_613170.base,
                         call_613170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613170, url, valid)

proc call*(call_613241: Call_AssociatePhoneNumberWithUser_612996; userId: string;
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
  var path_613242 = newJObject()
  var query_613244 = newJObject()
  var body_613245 = newJObject()
  add(query_613244, "operation", newJString(operation))
  add(path_613242, "userId", newJString(userId))
  if body != nil:
    body_613245 = body
  add(path_613242, "accountId", newJString(accountId))
  result = call_613241.call(path_613242, query_613244, nil, nil, body_613245)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_612996(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_612997, base: "/",
    url: url_AssociatePhoneNumberWithUser_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_613284 = ref object of OpenApiRestCall_612658
proc url_AssociatePhoneNumbersWithVoiceConnector_613286(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnector_613285(path: JsonNode;
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
  var valid_613287 = path.getOrDefault("voiceConnectorId")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "voiceConnectorId", valid_613287
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613288 = query.getOrDefault("operation")
  valid_613288 = validateParameter(valid_613288, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_613288 != nil:
    section.add "operation", valid_613288
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
  var valid_613289 = header.getOrDefault("X-Amz-Signature")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Signature", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Content-Sha256", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Date")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Date", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Credential")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Credential", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Security-Token")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Security-Token", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Algorithm")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Algorithm", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-SignedHeaders", valid_613295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613297: Call_AssociatePhoneNumbersWithVoiceConnector_613284;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_613297.validator(path, query, header, formData, body)
  let scheme = call_613297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613297.url(scheme.get, call_613297.host, call_613297.base,
                         call_613297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613297, url, valid)

proc call*(call_613298: Call_AssociatePhoneNumbersWithVoiceConnector_613284;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_613299 = newJObject()
  var query_613300 = newJObject()
  var body_613301 = newJObject()
  add(query_613300, "operation", newJString(operation))
  add(path_613299, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_613301 = body
  result = call_613298.call(path_613299, query_613300, nil, nil, body_613301)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_613284(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_613285, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_613286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnectorGroup_613302 = ref object of OpenApiRestCall_612658
proc url_AssociatePhoneNumbersWithVoiceConnectorGroup_613304(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnectorGroup_613303(path: JsonNode;
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
  var valid_613305 = path.getOrDefault("voiceConnectorGroupId")
  valid_613305 = validateParameter(valid_613305, JString, required = true,
                                 default = nil)
  if valid_613305 != nil:
    section.add "voiceConnectorGroupId", valid_613305
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613306 = query.getOrDefault("operation")
  valid_613306 = validateParameter(valid_613306, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_613306 != nil:
    section.add "operation", valid_613306
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
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613315: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_613302;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_613315.validator(path, query, header, formData, body)
  let scheme = call_613315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613315.url(scheme.get, call_613315.host, call_613315.base,
                         call_613315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613315, url, valid)

proc call*(call_613316: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_613302;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnectorGroup
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_613317 = newJObject()
  var query_613318 = newJObject()
  var body_613319 = newJObject()
  add(path_613317, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_613318, "operation", newJString(operation))
  if body != nil:
    body_613319 = body
  result = call_613316.call(path_613317, query_613318, nil, nil, body_613319)

var associatePhoneNumbersWithVoiceConnectorGroup* = Call_AssociatePhoneNumbersWithVoiceConnectorGroup_613302(
    name: "associatePhoneNumbersWithVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnectorGroup_613303,
    base: "/", url: url_AssociatePhoneNumbersWithVoiceConnectorGroup_613304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSigninDelegateGroupsWithAccount_613320 = ref object of OpenApiRestCall_612658
proc url_AssociateSigninDelegateGroupsWithAccount_613322(protocol: Scheme;
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

proc validate_AssociateSigninDelegateGroupsWithAccount_613321(path: JsonNode;
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
  var valid_613323 = path.getOrDefault("accountId")
  valid_613323 = validateParameter(valid_613323, JString, required = true,
                                 default = nil)
  if valid_613323 != nil:
    section.add "accountId", valid_613323
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613324 = query.getOrDefault("operation")
  valid_613324 = validateParameter(valid_613324, JString, required = true, default = newJString(
      "associate-signin-delegate-groups"))
  if valid_613324 != nil:
    section.add "operation", valid_613324
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
  var valid_613325 = header.getOrDefault("X-Amz-Signature")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Signature", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Content-Sha256", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Date")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Date", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Credential")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Credential", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Security-Token")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Security-Token", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Algorithm")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Algorithm", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-SignedHeaders", valid_613331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613333: Call_AssociateSigninDelegateGroupsWithAccount_613320;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ## 
  let valid = call_613333.validator(path, query, header, formData, body)
  let scheme = call_613333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613333.url(scheme.get, call_613333.host, call_613333.base,
                         call_613333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613333, url, valid)

proc call*(call_613334: Call_AssociateSigninDelegateGroupsWithAccount_613320;
          body: JsonNode; accountId: string;
          operation: string = "associate-signin-delegate-groups"): Recallable =
  ## associateSigninDelegateGroupsWithAccount
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613335 = newJObject()
  var query_613336 = newJObject()
  var body_613337 = newJObject()
  add(query_613336, "operation", newJString(operation))
  if body != nil:
    body_613337 = body
  add(path_613335, "accountId", newJString(accountId))
  result = call_613334.call(path_613335, query_613336, nil, nil, body_613337)

var associateSigninDelegateGroupsWithAccount* = Call_AssociateSigninDelegateGroupsWithAccount_613320(
    name: "associateSigninDelegateGroupsWithAccount", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}#operation=associate-signin-delegate-groups",
    validator: validate_AssociateSigninDelegateGroupsWithAccount_613321,
    base: "/", url: url_AssociateSigninDelegateGroupsWithAccount_613322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateAttendee_613338 = ref object of OpenApiRestCall_612658
proc url_BatchCreateAttendee_613340(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreateAttendee_613339(path: JsonNode; query: JsonNode;
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
  var valid_613341 = path.getOrDefault("meetingId")
  valid_613341 = validateParameter(valid_613341, JString, required = true,
                                 default = nil)
  if valid_613341 != nil:
    section.add "meetingId", valid_613341
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613342 = query.getOrDefault("operation")
  valid_613342 = validateParameter(valid_613342, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_613342 != nil:
    section.add "operation", valid_613342
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
  var valid_613343 = header.getOrDefault("X-Amz-Signature")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Signature", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Content-Sha256", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Date")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Date", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Credential")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Credential", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613351: Call_BatchCreateAttendee_613338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  let valid = call_613351.validator(path, query, header, formData, body)
  let scheme = call_613351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613351.url(scheme.get, call_613351.host, call_613351.base,
                         call_613351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613351, url, valid)

proc call*(call_613352: Call_BatchCreateAttendee_613338; body: JsonNode;
          meetingId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateAttendee
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_613353 = newJObject()
  var query_613354 = newJObject()
  var body_613355 = newJObject()
  add(query_613354, "operation", newJString(operation))
  if body != nil:
    body_613355 = body
  add(path_613353, "meetingId", newJString(meetingId))
  result = call_613352.call(path_613353, query_613354, nil, nil, body_613355)

var batchCreateAttendee* = Call_BatchCreateAttendee_613338(
    name: "batchCreateAttendee", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees#operation=batch-create",
    validator: validate_BatchCreateAttendee_613339, base: "/",
    url: url_BatchCreateAttendee_613340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateRoomMembership_613356 = ref object of OpenApiRestCall_612658
proc url_BatchCreateRoomMembership_613358(protocol: Scheme; host: string;
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

proc validate_BatchCreateRoomMembership_613357(path: JsonNode; query: JsonNode;
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
  var valid_613359 = path.getOrDefault("accountId")
  valid_613359 = validateParameter(valid_613359, JString, required = true,
                                 default = nil)
  if valid_613359 != nil:
    section.add "accountId", valid_613359
  var valid_613360 = path.getOrDefault("roomId")
  valid_613360 = validateParameter(valid_613360, JString, required = true,
                                 default = nil)
  if valid_613360 != nil:
    section.add "roomId", valid_613360
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613361 = query.getOrDefault("operation")
  valid_613361 = validateParameter(valid_613361, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_613361 != nil:
    section.add "operation", valid_613361
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
  var valid_613362 = header.getOrDefault("X-Amz-Signature")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Signature", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Content-Sha256", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Date")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Date", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Credential")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Credential", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Security-Token")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Security-Token", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Algorithm")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Algorithm", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-SignedHeaders", valid_613368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613370: Call_BatchCreateRoomMembership_613356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_613370.validator(path, query, header, formData, body)
  let scheme = call_613370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613370.url(scheme.get, call_613370.host, call_613370.base,
                         call_613370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613370, url, valid)

proc call*(call_613371: Call_BatchCreateRoomMembership_613356; body: JsonNode;
          accountId: string; roomId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateRoomMembership
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_613372 = newJObject()
  var query_613373 = newJObject()
  var body_613374 = newJObject()
  add(query_613373, "operation", newJString(operation))
  if body != nil:
    body_613374 = body
  add(path_613372, "accountId", newJString(accountId))
  add(path_613372, "roomId", newJString(roomId))
  result = call_613371.call(path_613372, query_613373, nil, nil, body_613374)

var batchCreateRoomMembership* = Call_BatchCreateRoomMembership_613356(
    name: "batchCreateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}/memberships#operation=batch-create",
    validator: validate_BatchCreateRoomMembership_613357, base: "/",
    url: url_BatchCreateRoomMembership_613358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_613375 = ref object of OpenApiRestCall_612658
proc url_BatchDeletePhoneNumber_613377(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeletePhoneNumber_613376(path: JsonNode; query: JsonNode;
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
  var valid_613378 = query.getOrDefault("operation")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_613378 != nil:
    section.add "operation", valid_613378
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
  var valid_613379 = header.getOrDefault("X-Amz-Signature")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Signature", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Content-Sha256", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Date")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Date", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Credential")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Credential", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Security-Token")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Security-Token", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Algorithm")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Algorithm", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-SignedHeaders", valid_613385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613387: Call_BatchDeletePhoneNumber_613375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_613387.validator(path, query, header, formData, body)
  let scheme = call_613387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613387.url(scheme.get, call_613387.host, call_613387.base,
                         call_613387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613387, url, valid)

proc call*(call_613388: Call_BatchDeletePhoneNumber_613375; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_613389 = newJObject()
  var body_613390 = newJObject()
  add(query_613389, "operation", newJString(operation))
  if body != nil:
    body_613390 = body
  result = call_613388.call(nil, query_613389, nil, nil, body_613390)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_613375(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_613376, base: "/",
    url: url_BatchDeletePhoneNumber_613377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_613391 = ref object of OpenApiRestCall_612658
proc url_BatchSuspendUser_613393(protocol: Scheme; host: string; base: string;
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

proc validate_BatchSuspendUser_613392(path: JsonNode; query: JsonNode;
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
  var valid_613394 = path.getOrDefault("accountId")
  valid_613394 = validateParameter(valid_613394, JString, required = true,
                                 default = nil)
  if valid_613394 != nil:
    section.add "accountId", valid_613394
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613395 = query.getOrDefault("operation")
  valid_613395 = validateParameter(valid_613395, JString, required = true,
                                 default = newJString("suspend"))
  if valid_613395 != nil:
    section.add "operation", valid_613395
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
  var valid_613396 = header.getOrDefault("X-Amz-Signature")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Signature", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Content-Sha256", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Date")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Date", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Credential")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Credential", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Security-Token")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Security-Token", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Algorithm")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Algorithm", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-SignedHeaders", valid_613402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613404: Call_BatchSuspendUser_613391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_613404.validator(path, query, header, formData, body)
  let scheme = call_613404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613404.url(scheme.get, call_613404.host, call_613404.base,
                         call_613404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613404, url, valid)

proc call*(call_613405: Call_BatchSuspendUser_613391; body: JsonNode;
          accountId: string; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613406 = newJObject()
  var query_613407 = newJObject()
  var body_613408 = newJObject()
  add(query_613407, "operation", newJString(operation))
  if body != nil:
    body_613408 = body
  add(path_613406, "accountId", newJString(accountId))
  result = call_613405.call(path_613406, query_613407, nil, nil, body_613408)

var batchSuspendUser* = Call_BatchSuspendUser_613391(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_613392, base: "/",
    url: url_BatchSuspendUser_613393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_613409 = ref object of OpenApiRestCall_612658
proc url_BatchUnsuspendUser_613411(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUnsuspendUser_613410(path: JsonNode; query: JsonNode;
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
  var valid_613412 = path.getOrDefault("accountId")
  valid_613412 = validateParameter(valid_613412, JString, required = true,
                                 default = nil)
  if valid_613412 != nil:
    section.add "accountId", valid_613412
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613413 = query.getOrDefault("operation")
  valid_613413 = validateParameter(valid_613413, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_613413 != nil:
    section.add "operation", valid_613413
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
  var valid_613414 = header.getOrDefault("X-Amz-Signature")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Signature", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Content-Sha256", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Date")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Date", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Credential")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Credential", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Security-Token")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Security-Token", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Algorithm")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Algorithm", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-SignedHeaders", valid_613420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613422: Call_BatchUnsuspendUser_613409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_613422.validator(path, query, header, formData, body)
  let scheme = call_613422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613422.url(scheme.get, call_613422.host, call_613422.base,
                         call_613422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613422, url, valid)

proc call*(call_613423: Call_BatchUnsuspendUser_613409; body: JsonNode;
          accountId: string; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613424 = newJObject()
  var query_613425 = newJObject()
  var body_613426 = newJObject()
  add(query_613425, "operation", newJString(operation))
  if body != nil:
    body_613426 = body
  add(path_613424, "accountId", newJString(accountId))
  result = call_613423.call(path_613424, query_613425, nil, nil, body_613426)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_613409(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_613410, base: "/",
    url: url_BatchUnsuspendUser_613411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_613427 = ref object of OpenApiRestCall_612658
proc url_BatchUpdatePhoneNumber_613429(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdatePhoneNumber_613428(path: JsonNode; query: JsonNode;
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
  var valid_613430 = query.getOrDefault("operation")
  valid_613430 = validateParameter(valid_613430, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_613430 != nil:
    section.add "operation", valid_613430
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
  var valid_613431 = header.getOrDefault("X-Amz-Signature")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Signature", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Content-Sha256", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Date")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Date", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Credential")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Credential", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Security-Token")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Security-Token", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Algorithm")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Algorithm", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-SignedHeaders", valid_613437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613439: Call_BatchUpdatePhoneNumber_613427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_613439.validator(path, query, header, formData, body)
  let scheme = call_613439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613439.url(scheme.get, call_613439.host, call_613439.base,
                         call_613439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613439, url, valid)

proc call*(call_613440: Call_BatchUpdatePhoneNumber_613427; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_613441 = newJObject()
  var body_613442 = newJObject()
  add(query_613441, "operation", newJString(operation))
  if body != nil:
    body_613442 = body
  result = call_613440.call(nil, query_613441, nil, nil, body_613442)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_613427(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_613428, base: "/",
    url: url_BatchUpdatePhoneNumber_613429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_613464 = ref object of OpenApiRestCall_612658
proc url_BatchUpdateUser_613466(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateUser_613465(path: JsonNode; query: JsonNode;
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
  var valid_613467 = path.getOrDefault("accountId")
  valid_613467 = validateParameter(valid_613467, JString, required = true,
                                 default = nil)
  if valid_613467 != nil:
    section.add "accountId", valid_613467
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
  var valid_613468 = header.getOrDefault("X-Amz-Signature")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Signature", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Content-Sha256", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Date")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Date", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Credential")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Credential", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Security-Token")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Security-Token", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Algorithm")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Algorithm", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-SignedHeaders", valid_613474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613476: Call_BatchUpdateUser_613464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_613476.validator(path, query, header, formData, body)
  let scheme = call_613476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613476.url(scheme.get, call_613476.host, call_613476.base,
                         call_613476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613476, url, valid)

proc call*(call_613477: Call_BatchUpdateUser_613464; body: JsonNode;
          accountId: string): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613478 = newJObject()
  var body_613479 = newJObject()
  if body != nil:
    body_613479 = body
  add(path_613478, "accountId", newJString(accountId))
  result = call_613477.call(path_613478, nil, nil, nil, body_613479)

var batchUpdateUser* = Call_BatchUpdateUser_613464(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_613465,
    base: "/", url: url_BatchUpdateUser_613466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_613443 = ref object of OpenApiRestCall_612658
proc url_ListUsers_613445(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_613444(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613446 = path.getOrDefault("accountId")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "accountId", valid_613446
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
  var valid_613447 = query.getOrDefault("MaxResults")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "MaxResults", valid_613447
  var valid_613448 = query.getOrDefault("user-email")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "user-email", valid_613448
  var valid_613449 = query.getOrDefault("NextToken")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "NextToken", valid_613449
  var valid_613450 = query.getOrDefault("user-type")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = newJString("PrivateUser"))
  if valid_613450 != nil:
    section.add "user-type", valid_613450
  var valid_613451 = query.getOrDefault("max-results")
  valid_613451 = validateParameter(valid_613451, JInt, required = false, default = nil)
  if valid_613451 != nil:
    section.add "max-results", valid_613451
  var valid_613452 = query.getOrDefault("next-token")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "next-token", valid_613452
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
  var valid_613453 = header.getOrDefault("X-Amz-Signature")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Signature", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Content-Sha256", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Date")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Date", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Credential")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Credential", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Security-Token")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Security-Token", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Algorithm")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Algorithm", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-SignedHeaders", valid_613459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613460: Call_ListUsers_613443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_613460.validator(path, query, header, formData, body)
  let scheme = call_613460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613460.url(scheme.get, call_613460.host, call_613460.base,
                         call_613460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613460, url, valid)

proc call*(call_613461: Call_ListUsers_613443; accountId: string;
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
  var path_613462 = newJObject()
  var query_613463 = newJObject()
  add(query_613463, "MaxResults", newJString(MaxResults))
  add(query_613463, "user-email", newJString(userEmail))
  add(query_613463, "NextToken", newJString(NextToken))
  add(query_613463, "user-type", newJString(userType))
  add(query_613463, "max-results", newJInt(maxResults))
  add(path_613462, "accountId", newJString(accountId))
  add(query_613463, "next-token", newJString(nextToken))
  result = call_613461.call(path_613462, query_613463, nil, nil, nil)

var listUsers* = Call_ListUsers_613443(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_613444,
                                    base: "/", url: url_ListUsers_613445,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_613499 = ref object of OpenApiRestCall_612658
proc url_CreateAccount_613501(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAccount_613500(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613502 = header.getOrDefault("X-Amz-Signature")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Signature", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Content-Sha256", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Date")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Date", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Credential")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Credential", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Security-Token")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Security-Token", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Algorithm")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Algorithm", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-SignedHeaders", valid_613508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613510: Call_CreateAccount_613499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_613510.validator(path, query, header, formData, body)
  let scheme = call_613510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613510.url(scheme.get, call_613510.host, call_613510.base,
                         call_613510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613510, url, valid)

proc call*(call_613511: Call_CreateAccount_613499; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_613512 = newJObject()
  if body != nil:
    body_613512 = body
  result = call_613511.call(nil, nil, nil, nil, body_613512)

var createAccount* = Call_CreateAccount_613499(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_613500, base: "/", url: url_CreateAccount_613501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_613480 = ref object of OpenApiRestCall_612658
proc url_ListAccounts_613482(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccounts_613481(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613483 = query.getOrDefault("name")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "name", valid_613483
  var valid_613484 = query.getOrDefault("MaxResults")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "MaxResults", valid_613484
  var valid_613485 = query.getOrDefault("user-email")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "user-email", valid_613485
  var valid_613486 = query.getOrDefault("NextToken")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "NextToken", valid_613486
  var valid_613487 = query.getOrDefault("max-results")
  valid_613487 = validateParameter(valid_613487, JInt, required = false, default = nil)
  if valid_613487 != nil:
    section.add "max-results", valid_613487
  var valid_613488 = query.getOrDefault("next-token")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "next-token", valid_613488
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
  var valid_613489 = header.getOrDefault("X-Amz-Signature")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Signature", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Content-Sha256", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Date")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Date", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Credential")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Credential", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Security-Token")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Security-Token", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Algorithm")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Algorithm", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-SignedHeaders", valid_613495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613496: Call_ListAccounts_613480; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_613496.validator(path, query, header, formData, body)
  let scheme = call_613496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613496.url(scheme.get, call_613496.host, call_613496.base,
                         call_613496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613496, url, valid)

proc call*(call_613497: Call_ListAccounts_613480; name: string = "";
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
  var query_613498 = newJObject()
  add(query_613498, "name", newJString(name))
  add(query_613498, "MaxResults", newJString(MaxResults))
  add(query_613498, "user-email", newJString(userEmail))
  add(query_613498, "NextToken", newJString(NextToken))
  add(query_613498, "max-results", newJInt(maxResults))
  add(query_613498, "next-token", newJString(nextToken))
  result = call_613497.call(nil, query_613498, nil, nil, nil)

var listAccounts* = Call_ListAccounts_613480(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_613481, base: "/", url: url_ListAccounts_613482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAttendee_613532 = ref object of OpenApiRestCall_612658
proc url_CreateAttendee_613534(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAttendee_613533(path: JsonNode; query: JsonNode;
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
  var valid_613535 = path.getOrDefault("meetingId")
  valid_613535 = validateParameter(valid_613535, JString, required = true,
                                 default = nil)
  if valid_613535 != nil:
    section.add "meetingId", valid_613535
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
  var valid_613536 = header.getOrDefault("X-Amz-Signature")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Signature", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Content-Sha256", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Date")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Date", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Credential")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Credential", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Security-Token")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Security-Token", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Algorithm")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Algorithm", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-SignedHeaders", valid_613542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613544: Call_CreateAttendee_613532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613544.validator(path, query, header, formData, body)
  let scheme = call_613544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613544.url(scheme.get, call_613544.host, call_613544.base,
                         call_613544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613544, url, valid)

proc call*(call_613545: Call_CreateAttendee_613532; body: JsonNode; meetingId: string): Recallable =
  ## createAttendee
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_613546 = newJObject()
  var body_613547 = newJObject()
  if body != nil:
    body_613547 = body
  add(path_613546, "meetingId", newJString(meetingId))
  result = call_613545.call(path_613546, nil, nil, nil, body_613547)

var createAttendee* = Call_CreateAttendee_613532(name: "createAttendee",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_CreateAttendee_613533,
    base: "/", url: url_CreateAttendee_613534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttendees_613513 = ref object of OpenApiRestCall_612658
proc url_ListAttendees_613515(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttendees_613514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613516 = path.getOrDefault("meetingId")
  valid_613516 = validateParameter(valid_613516, JString, required = true,
                                 default = nil)
  if valid_613516 != nil:
    section.add "meetingId", valid_613516
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
  var valid_613517 = query.getOrDefault("MaxResults")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "MaxResults", valid_613517
  var valid_613518 = query.getOrDefault("NextToken")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "NextToken", valid_613518
  var valid_613519 = query.getOrDefault("max-results")
  valid_613519 = validateParameter(valid_613519, JInt, required = false, default = nil)
  if valid_613519 != nil:
    section.add "max-results", valid_613519
  var valid_613520 = query.getOrDefault("next-token")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "next-token", valid_613520
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
  var valid_613521 = header.getOrDefault("X-Amz-Signature")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Signature", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Content-Sha256", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Date")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Date", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Credential")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Credential", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Security-Token")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Security-Token", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Algorithm")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Algorithm", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-SignedHeaders", valid_613527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613528: Call_ListAttendees_613513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613528.validator(path, query, header, formData, body)
  let scheme = call_613528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613528.url(scheme.get, call_613528.host, call_613528.base,
                         call_613528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613528, url, valid)

proc call*(call_613529: Call_ListAttendees_613513; meetingId: string;
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
  var path_613530 = newJObject()
  var query_613531 = newJObject()
  add(query_613531, "MaxResults", newJString(MaxResults))
  add(query_613531, "NextToken", newJString(NextToken))
  add(query_613531, "max-results", newJInt(maxResults))
  add(path_613530, "meetingId", newJString(meetingId))
  add(query_613531, "next-token", newJString(nextToken))
  result = call_613529.call(path_613530, query_613531, nil, nil, nil)

var listAttendees* = Call_ListAttendees_613513(name: "listAttendees",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_ListAttendees_613514,
    base: "/", url: url_ListAttendees_613515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_613567 = ref object of OpenApiRestCall_612658
proc url_CreateBot_613569(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateBot_613568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613570 = path.getOrDefault("accountId")
  valid_613570 = validateParameter(valid_613570, JString, required = true,
                                 default = nil)
  if valid_613570 != nil:
    section.add "accountId", valid_613570
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
  var valid_613571 = header.getOrDefault("X-Amz-Signature")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Signature", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Content-Sha256", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Date")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Date", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Credential")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Credential", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Security-Token")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Security-Token", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Algorithm")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Algorithm", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-SignedHeaders", valid_613577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613579: Call_CreateBot_613567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_613579.validator(path, query, header, formData, body)
  let scheme = call_613579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613579.url(scheme.get, call_613579.host, call_613579.base,
                         call_613579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613579, url, valid)

proc call*(call_613580: Call_CreateBot_613567; body: JsonNode; accountId: string): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613581 = newJObject()
  var body_613582 = newJObject()
  if body != nil:
    body_613582 = body
  add(path_613581, "accountId", newJString(accountId))
  result = call_613580.call(path_613581, nil, nil, nil, body_613582)

var createBot* = Call_CreateBot_613567(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_613568,
                                    base: "/", url: url_CreateBot_613569,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_613548 = ref object of OpenApiRestCall_612658
proc url_ListBots_613550(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListBots_613549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613551 = path.getOrDefault("accountId")
  valid_613551 = validateParameter(valid_613551, JString, required = true,
                                 default = nil)
  if valid_613551 != nil:
    section.add "accountId", valid_613551
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
  var valid_613552 = query.getOrDefault("MaxResults")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "MaxResults", valid_613552
  var valid_613553 = query.getOrDefault("NextToken")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "NextToken", valid_613553
  var valid_613554 = query.getOrDefault("max-results")
  valid_613554 = validateParameter(valid_613554, JInt, required = false, default = nil)
  if valid_613554 != nil:
    section.add "max-results", valid_613554
  var valid_613555 = query.getOrDefault("next-token")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "next-token", valid_613555
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
  var valid_613556 = header.getOrDefault("X-Amz-Signature")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Signature", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Content-Sha256", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Date")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Date", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Credential")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Credential", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Security-Token")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Security-Token", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Algorithm")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Algorithm", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-SignedHeaders", valid_613562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613563: Call_ListBots_613548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_613563.validator(path, query, header, formData, body)
  let scheme = call_613563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613563.url(scheme.get, call_613563.host, call_613563.base,
                         call_613563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613563, url, valid)

proc call*(call_613564: Call_ListBots_613548; accountId: string;
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
  var path_613565 = newJObject()
  var query_613566 = newJObject()
  add(query_613566, "MaxResults", newJString(MaxResults))
  add(query_613566, "NextToken", newJString(NextToken))
  add(query_613566, "max-results", newJInt(maxResults))
  add(path_613565, "accountId", newJString(accountId))
  add(query_613566, "next-token", newJString(nextToken))
  result = call_613564.call(path_613565, query_613566, nil, nil, nil)

var listBots* = Call_ListBots_613548(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_613549, base: "/",
                                  url: url_ListBots_613550,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMeeting_613600 = ref object of OpenApiRestCall_612658
proc url_CreateMeeting_613602(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMeeting_613601(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613603 = header.getOrDefault("X-Amz-Signature")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Signature", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Content-Sha256", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Date")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Date", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Credential")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Credential", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Security-Token")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Security-Token", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Algorithm")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Algorithm", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-SignedHeaders", valid_613609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613611: Call_CreateMeeting_613600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613611.validator(path, query, header, formData, body)
  let scheme = call_613611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613611.url(scheme.get, call_613611.host, call_613611.base,
                         call_613611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613611, url, valid)

proc call*(call_613612: Call_CreateMeeting_613600; body: JsonNode): Recallable =
  ## createMeeting
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  var body_613613 = newJObject()
  if body != nil:
    body_613613 = body
  result = call_613612.call(nil, nil, nil, nil, body_613613)

var createMeeting* = Call_CreateMeeting_613600(name: "createMeeting",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_CreateMeeting_613601, base: "/", url: url_CreateMeeting_613602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeetings_613583 = ref object of OpenApiRestCall_612658
proc url_ListMeetings_613585(protocol: Scheme; host: string; base: string;
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

proc validate_ListMeetings_613584(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613586 = query.getOrDefault("MaxResults")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "MaxResults", valid_613586
  var valid_613587 = query.getOrDefault("NextToken")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "NextToken", valid_613587
  var valid_613588 = query.getOrDefault("max-results")
  valid_613588 = validateParameter(valid_613588, JInt, required = false, default = nil)
  if valid_613588 != nil:
    section.add "max-results", valid_613588
  var valid_613589 = query.getOrDefault("next-token")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "next-token", valid_613589
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
  var valid_613590 = header.getOrDefault("X-Amz-Signature")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Signature", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Content-Sha256", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Date")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Date", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Credential")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Credential", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Security-Token")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Security-Token", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Algorithm")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Algorithm", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-SignedHeaders", valid_613596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613597: Call_ListMeetings_613583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613597.validator(path, query, header, formData, body)
  let scheme = call_613597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613597.url(scheme.get, call_613597.host, call_613597.base,
                         call_613597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613597, url, valid)

proc call*(call_613598: Call_ListMeetings_613583; MaxResults: string = "";
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
  var query_613599 = newJObject()
  add(query_613599, "MaxResults", newJString(MaxResults))
  add(query_613599, "NextToken", newJString(NextToken))
  add(query_613599, "max-results", newJInt(maxResults))
  add(query_613599, "next-token", newJString(nextToken))
  result = call_613598.call(nil, query_613599, nil, nil, nil)

var listMeetings* = Call_ListMeetings_613583(name: "listMeetings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_ListMeetings_613584, base: "/", url: url_ListMeetings_613585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_613631 = ref object of OpenApiRestCall_612658
proc url_CreatePhoneNumberOrder_613633(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePhoneNumberOrder_613632(path: JsonNode; query: JsonNode;
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
  var valid_613634 = header.getOrDefault("X-Amz-Signature")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Signature", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Content-Sha256", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Date")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Date", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Credential")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Credential", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Security-Token")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Security-Token", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Algorithm")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Algorithm", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-SignedHeaders", valid_613640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613642: Call_CreatePhoneNumberOrder_613631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_613642.validator(path, query, header, formData, body)
  let scheme = call_613642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613642.url(scheme.get, call_613642.host, call_613642.base,
                         call_613642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613642, url, valid)

proc call*(call_613643: Call_CreatePhoneNumberOrder_613631; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_613644 = newJObject()
  if body != nil:
    body_613644 = body
  result = call_613643.call(nil, nil, nil, nil, body_613644)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_613631(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_613632, base: "/",
    url: url_CreatePhoneNumberOrder_613633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_613614 = ref object of OpenApiRestCall_612658
proc url_ListPhoneNumberOrders_613616(protocol: Scheme; host: string; base: string;
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

proc validate_ListPhoneNumberOrders_613615(path: JsonNode; query: JsonNode;
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
  var valid_613617 = query.getOrDefault("MaxResults")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "MaxResults", valid_613617
  var valid_613618 = query.getOrDefault("NextToken")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "NextToken", valid_613618
  var valid_613619 = query.getOrDefault("max-results")
  valid_613619 = validateParameter(valid_613619, JInt, required = false, default = nil)
  if valid_613619 != nil:
    section.add "max-results", valid_613619
  var valid_613620 = query.getOrDefault("next-token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "next-token", valid_613620
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
  var valid_613621 = header.getOrDefault("X-Amz-Signature")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Signature", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Content-Sha256", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Date")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Date", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Credential")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Credential", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Security-Token")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Security-Token", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Algorithm")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Algorithm", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-SignedHeaders", valid_613627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613628: Call_ListPhoneNumberOrders_613614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_613628.validator(path, query, header, formData, body)
  let scheme = call_613628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613628.url(scheme.get, call_613628.host, call_613628.base,
                         call_613628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613628, url, valid)

proc call*(call_613629: Call_ListPhoneNumberOrders_613614; MaxResults: string = "";
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
  var query_613630 = newJObject()
  add(query_613630, "MaxResults", newJString(MaxResults))
  add(query_613630, "NextToken", newJString(NextToken))
  add(query_613630, "max-results", newJInt(maxResults))
  add(query_613630, "next-token", newJString(nextToken))
  result = call_613629.call(nil, query_613630, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_613614(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_613615, base: "/",
    url: url_ListPhoneNumberOrders_613616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_613665 = ref object of OpenApiRestCall_612658
proc url_CreateRoom_613667(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateRoom_613666(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613668 = path.getOrDefault("accountId")
  valid_613668 = validateParameter(valid_613668, JString, required = true,
                                 default = nil)
  if valid_613668 != nil:
    section.add "accountId", valid_613668
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
  var valid_613669 = header.getOrDefault("X-Amz-Signature")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Signature", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Content-Sha256", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Date")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Date", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Credential")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Credential", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Security-Token")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Security-Token", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Algorithm")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Algorithm", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-SignedHeaders", valid_613675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613677: Call_CreateRoom_613665; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a chat room for the specified Amazon Chime account.
  ## 
  let valid = call_613677.validator(path, query, header, formData, body)
  let scheme = call_613677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613677.url(scheme.get, call_613677.host, call_613677.base,
                         call_613677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613677, url, valid)

proc call*(call_613678: Call_CreateRoom_613665; body: JsonNode; accountId: string): Recallable =
  ## createRoom
  ## Creates a chat room for the specified Amazon Chime account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613679 = newJObject()
  var body_613680 = newJObject()
  if body != nil:
    body_613680 = body
  add(path_613679, "accountId", newJString(accountId))
  result = call_613678.call(path_613679, nil, nil, nil, body_613680)

var createRoom* = Call_CreateRoom_613665(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/rooms",
                                      validator: validate_CreateRoom_613666,
                                      base: "/", url: url_CreateRoom_613667,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRooms_613645 = ref object of OpenApiRestCall_612658
proc url_ListRooms_613647(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListRooms_613646(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613648 = path.getOrDefault("accountId")
  valid_613648 = validateParameter(valid_613648, JString, required = true,
                                 default = nil)
  if valid_613648 != nil:
    section.add "accountId", valid_613648
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
  var valid_613649 = query.getOrDefault("member-id")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "member-id", valid_613649
  var valid_613650 = query.getOrDefault("MaxResults")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "MaxResults", valid_613650
  var valid_613651 = query.getOrDefault("NextToken")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "NextToken", valid_613651
  var valid_613652 = query.getOrDefault("max-results")
  valid_613652 = validateParameter(valid_613652, JInt, required = false, default = nil)
  if valid_613652 != nil:
    section.add "max-results", valid_613652
  var valid_613653 = query.getOrDefault("next-token")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "next-token", valid_613653
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
  var valid_613654 = header.getOrDefault("X-Amz-Signature")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Signature", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Content-Sha256", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Date")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Date", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Credential")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Credential", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Security-Token")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Security-Token", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Algorithm")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Algorithm", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-SignedHeaders", valid_613660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613661: Call_ListRooms_613645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the room details for the specified Amazon Chime account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  let valid = call_613661.validator(path, query, header, formData, body)
  let scheme = call_613661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613661.url(scheme.get, call_613661.host, call_613661.base,
                         call_613661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613661, url, valid)

proc call*(call_613662: Call_ListRooms_613645; accountId: string;
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
  var path_613663 = newJObject()
  var query_613664 = newJObject()
  add(query_613664, "member-id", newJString(memberId))
  add(query_613664, "MaxResults", newJString(MaxResults))
  add(query_613664, "NextToken", newJString(NextToken))
  add(query_613664, "max-results", newJInt(maxResults))
  add(path_613663, "accountId", newJString(accountId))
  add(query_613664, "next-token", newJString(nextToken))
  result = call_613662.call(path_613663, query_613664, nil, nil, nil)

var listRooms* = Call_ListRooms_613645(name: "listRooms", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/rooms",
                                    validator: validate_ListRooms_613646,
                                    base: "/", url: url_ListRooms_613647,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoomMembership_613701 = ref object of OpenApiRestCall_612658
proc url_CreateRoomMembership_613703(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoomMembership_613702(path: JsonNode; query: JsonNode;
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
  var valid_613704 = path.getOrDefault("accountId")
  valid_613704 = validateParameter(valid_613704, JString, required = true,
                                 default = nil)
  if valid_613704 != nil:
    section.add "accountId", valid_613704
  var valid_613705 = path.getOrDefault("roomId")
  valid_613705 = validateParameter(valid_613705, JString, required = true,
                                 default = nil)
  if valid_613705 != nil:
    section.add "roomId", valid_613705
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
  var valid_613706 = header.getOrDefault("X-Amz-Signature")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Signature", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Content-Sha256", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Date")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Date", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Credential")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Credential", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Security-Token")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Security-Token", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Algorithm")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Algorithm", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-SignedHeaders", valid_613712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613714: Call_CreateRoomMembership_613701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_613714.validator(path, query, header, formData, body)
  let scheme = call_613714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613714.url(scheme.get, call_613714.host, call_613714.base,
                         call_613714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613714, url, valid)

proc call*(call_613715: Call_CreateRoomMembership_613701; body: JsonNode;
          accountId: string; roomId: string): Recallable =
  ## createRoomMembership
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_613716 = newJObject()
  var body_613717 = newJObject()
  if body != nil:
    body_613717 = body
  add(path_613716, "accountId", newJString(accountId))
  add(path_613716, "roomId", newJString(roomId))
  result = call_613715.call(path_613716, nil, nil, nil, body_613717)

var createRoomMembership* = Call_CreateRoomMembership_613701(
    name: "createRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_CreateRoomMembership_613702, base: "/",
    url: url_CreateRoomMembership_613703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoomMemberships_613681 = ref object of OpenApiRestCall_612658
proc url_ListRoomMemberships_613683(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoomMemberships_613682(path: JsonNode; query: JsonNode;
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
  var valid_613684 = path.getOrDefault("accountId")
  valid_613684 = validateParameter(valid_613684, JString, required = true,
                                 default = nil)
  if valid_613684 != nil:
    section.add "accountId", valid_613684
  var valid_613685 = path.getOrDefault("roomId")
  valid_613685 = validateParameter(valid_613685, JString, required = true,
                                 default = nil)
  if valid_613685 != nil:
    section.add "roomId", valid_613685
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
  var valid_613686 = query.getOrDefault("MaxResults")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "MaxResults", valid_613686
  var valid_613687 = query.getOrDefault("NextToken")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "NextToken", valid_613687
  var valid_613688 = query.getOrDefault("max-results")
  valid_613688 = validateParameter(valid_613688, JInt, required = false, default = nil)
  if valid_613688 != nil:
    section.add "max-results", valid_613688
  var valid_613689 = query.getOrDefault("next-token")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "next-token", valid_613689
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
  var valid_613690 = header.getOrDefault("X-Amz-Signature")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Signature", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Content-Sha256", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Date")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Date", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Credential")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Credential", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Security-Token")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Security-Token", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Algorithm")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Algorithm", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-SignedHeaders", valid_613696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613697: Call_ListRoomMemberships_613681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the membership details for the specified room, such as the members' IDs, email addresses, and names.
  ## 
  let valid = call_613697.validator(path, query, header, formData, body)
  let scheme = call_613697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613697.url(scheme.get, call_613697.host, call_613697.base,
                         call_613697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613697, url, valid)

proc call*(call_613698: Call_ListRoomMemberships_613681; accountId: string;
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
  var path_613699 = newJObject()
  var query_613700 = newJObject()
  add(query_613700, "MaxResults", newJString(MaxResults))
  add(query_613700, "NextToken", newJString(NextToken))
  add(query_613700, "max-results", newJInt(maxResults))
  add(path_613699, "accountId", newJString(accountId))
  add(path_613699, "roomId", newJString(roomId))
  add(query_613700, "next-token", newJString(nextToken))
  result = call_613698.call(path_613699, query_613700, nil, nil, nil)

var listRoomMemberships* = Call_ListRoomMemberships_613681(
    name: "listRoomMemberships", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_ListRoomMemberships_613682, base: "/",
    url: url_ListRoomMemberships_613683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_613718 = ref object of OpenApiRestCall_612658
proc url_CreateUser_613720(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_613719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613721 = path.getOrDefault("accountId")
  valid_613721 = validateParameter(valid_613721, JString, required = true,
                                 default = nil)
  if valid_613721 != nil:
    section.add "accountId", valid_613721
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_613722 = query.getOrDefault("operation")
  valid_613722 = validateParameter(valid_613722, JString, required = true,
                                 default = newJString("create"))
  if valid_613722 != nil:
    section.add "operation", valid_613722
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
  var valid_613723 = header.getOrDefault("X-Amz-Signature")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Signature", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Content-Sha256", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Date")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Date", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Credential")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Credential", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Security-Token")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Security-Token", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Algorithm")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Algorithm", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-SignedHeaders", valid_613729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613731: Call_CreateUser_613718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user under the specified Amazon Chime account.
  ## 
  let valid = call_613731.validator(path, query, header, formData, body)
  let scheme = call_613731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613731.url(scheme.get, call_613731.host, call_613731.base,
                         call_613731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613731, url, valid)

proc call*(call_613732: Call_CreateUser_613718; body: JsonNode; accountId: string;
          operation: string = "create"): Recallable =
  ## createUser
  ## Creates a user under the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613733 = newJObject()
  var query_613734 = newJObject()
  var body_613735 = newJObject()
  add(query_613734, "operation", newJString(operation))
  if body != nil:
    body_613735 = body
  add(path_613733, "accountId", newJString(accountId))
  result = call_613732.call(path_613733, query_613734, nil, nil, body_613735)

var createUser* = Call_CreateUser_613718(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=create",
                                      validator: validate_CreateUser_613719,
                                      base: "/", url: url_CreateUser_613720,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_613753 = ref object of OpenApiRestCall_612658
proc url_CreateVoiceConnector_613755(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVoiceConnector_613754(path: JsonNode; query: JsonNode;
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
  var valid_613756 = header.getOrDefault("X-Amz-Signature")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Signature", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Content-Sha256", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Date")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Date", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Credential")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Credential", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Security-Token")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Security-Token", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Algorithm")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Algorithm", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-SignedHeaders", valid_613762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613764: Call_CreateVoiceConnector_613753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  let valid = call_613764.validator(path, query, header, formData, body)
  let scheme = call_613764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613764.url(scheme.get, call_613764.host, call_613764.base,
                         call_613764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613764, url, valid)

proc call*(call_613765: Call_CreateVoiceConnector_613753; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ##   body: JObject (required)
  var body_613766 = newJObject()
  if body != nil:
    body_613766 = body
  result = call_613765.call(nil, nil, nil, nil, body_613766)

var createVoiceConnector* = Call_CreateVoiceConnector_613753(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_613754, base: "/",
    url: url_CreateVoiceConnector_613755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_613736 = ref object of OpenApiRestCall_612658
proc url_ListVoiceConnectors_613738(protocol: Scheme; host: string; base: string;
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

proc validate_ListVoiceConnectors_613737(path: JsonNode; query: JsonNode;
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
  var valid_613739 = query.getOrDefault("MaxResults")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "MaxResults", valid_613739
  var valid_613740 = query.getOrDefault("NextToken")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "NextToken", valid_613740
  var valid_613741 = query.getOrDefault("max-results")
  valid_613741 = validateParameter(valid_613741, JInt, required = false, default = nil)
  if valid_613741 != nil:
    section.add "max-results", valid_613741
  var valid_613742 = query.getOrDefault("next-token")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "next-token", valid_613742
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
  var valid_613743 = header.getOrDefault("X-Amz-Signature")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Signature", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Content-Sha256", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Date")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Date", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Credential")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Credential", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Security-Token")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Security-Token", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Algorithm")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Algorithm", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-SignedHeaders", valid_613749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613750: Call_ListVoiceConnectors_613736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_613750.validator(path, query, header, formData, body)
  let scheme = call_613750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613750.url(scheme.get, call_613750.host, call_613750.base,
                         call_613750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613750, url, valid)

proc call*(call_613751: Call_ListVoiceConnectors_613736; MaxResults: string = "";
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
  var query_613752 = newJObject()
  add(query_613752, "MaxResults", newJString(MaxResults))
  add(query_613752, "NextToken", newJString(NextToken))
  add(query_613752, "max-results", newJInt(maxResults))
  add(query_613752, "next-token", newJString(nextToken))
  result = call_613751.call(nil, query_613752, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_613736(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_613737, base: "/",
    url: url_ListVoiceConnectors_613738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnectorGroup_613784 = ref object of OpenApiRestCall_612658
proc url_CreateVoiceConnectorGroup_613786(protocol: Scheme; host: string;
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

proc validate_CreateVoiceConnectorGroup_613785(path: JsonNode; query: JsonNode;
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
  var valid_613787 = header.getOrDefault("X-Amz-Signature")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Signature", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Content-Sha256", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Date")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Date", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Credential")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Credential", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Security-Token")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Security-Token", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Algorithm")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Algorithm", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-SignedHeaders", valid_613793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613795: Call_CreateVoiceConnectorGroup_613784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  let valid = call_613795.validator(path, query, header, formData, body)
  let scheme = call_613795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613795.url(scheme.get, call_613795.host, call_613795.base,
                         call_613795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613795, url, valid)

proc call*(call_613796: Call_CreateVoiceConnectorGroup_613784; body: JsonNode): Recallable =
  ## createVoiceConnectorGroup
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ##   body: JObject (required)
  var body_613797 = newJObject()
  if body != nil:
    body_613797 = body
  result = call_613796.call(nil, nil, nil, nil, body_613797)

var createVoiceConnectorGroup* = Call_CreateVoiceConnectorGroup_613784(
    name: "createVoiceConnectorGroup", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_CreateVoiceConnectorGroup_613785, base: "/",
    url: url_CreateVoiceConnectorGroup_613786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorGroups_613767 = ref object of OpenApiRestCall_612658
proc url_ListVoiceConnectorGroups_613769(protocol: Scheme; host: string;
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

proc validate_ListVoiceConnectorGroups_613768(path: JsonNode; query: JsonNode;
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
  var valid_613770 = query.getOrDefault("MaxResults")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "MaxResults", valid_613770
  var valid_613771 = query.getOrDefault("NextToken")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "NextToken", valid_613771
  var valid_613772 = query.getOrDefault("max-results")
  valid_613772 = validateParameter(valid_613772, JInt, required = false, default = nil)
  if valid_613772 != nil:
    section.add "max-results", valid_613772
  var valid_613773 = query.getOrDefault("next-token")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "next-token", valid_613773
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
  var valid_613774 = header.getOrDefault("X-Amz-Signature")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Signature", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Content-Sha256", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Date")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Date", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Credential")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Credential", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Security-Token")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Security-Token", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Algorithm")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Algorithm", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-SignedHeaders", valid_613780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613781: Call_ListVoiceConnectorGroups_613767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  let valid = call_613781.validator(path, query, header, formData, body)
  let scheme = call_613781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613781.url(scheme.get, call_613781.host, call_613781.base,
                         call_613781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613781, url, valid)

proc call*(call_613782: Call_ListVoiceConnectorGroups_613767;
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
  var query_613783 = newJObject()
  add(query_613783, "MaxResults", newJString(MaxResults))
  add(query_613783, "NextToken", newJString(NextToken))
  add(query_613783, "max-results", newJInt(maxResults))
  add(query_613783, "next-token", newJString(nextToken))
  result = call_613782.call(nil, query_613783, nil, nil, nil)

var listVoiceConnectorGroups* = Call_ListVoiceConnectorGroups_613767(
    name: "listVoiceConnectorGroups", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_ListVoiceConnectorGroups_613768, base: "/",
    url: url_ListVoiceConnectorGroups_613769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_613812 = ref object of OpenApiRestCall_612658
proc url_UpdateAccount_613814(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_613813(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613815 = path.getOrDefault("accountId")
  valid_613815 = validateParameter(valid_613815, JString, required = true,
                                 default = nil)
  if valid_613815 != nil:
    section.add "accountId", valid_613815
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
  var valid_613816 = header.getOrDefault("X-Amz-Signature")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Signature", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Content-Sha256", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Date")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Date", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Credential")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Credential", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Security-Token")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Security-Token", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Algorithm")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Algorithm", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-SignedHeaders", valid_613822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613824: Call_UpdateAccount_613812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_613824.validator(path, query, header, formData, body)
  let scheme = call_613824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613824.url(scheme.get, call_613824.host, call_613824.base,
                         call_613824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613824, url, valid)

proc call*(call_613825: Call_UpdateAccount_613812; body: JsonNode; accountId: string): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613826 = newJObject()
  var body_613827 = newJObject()
  if body != nil:
    body_613827 = body
  add(path_613826, "accountId", newJString(accountId))
  result = call_613825.call(path_613826, nil, nil, nil, body_613827)

var updateAccount* = Call_UpdateAccount_613812(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_613813,
    base: "/", url: url_UpdateAccount_613814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_613798 = ref object of OpenApiRestCall_612658
proc url_GetAccount_613800(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_613799(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613801 = path.getOrDefault("accountId")
  valid_613801 = validateParameter(valid_613801, JString, required = true,
                                 default = nil)
  if valid_613801 != nil:
    section.add "accountId", valid_613801
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
  var valid_613802 = header.getOrDefault("X-Amz-Signature")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Signature", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Content-Sha256", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Date")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Date", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Credential")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Credential", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Security-Token")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Security-Token", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Algorithm")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Algorithm", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-SignedHeaders", valid_613808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613809: Call_GetAccount_613798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_613809.validator(path, query, header, formData, body)
  let scheme = call_613809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613809.url(scheme.get, call_613809.host, call_613809.base,
                         call_613809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613809, url, valid)

proc call*(call_613810: Call_GetAccount_613798; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613811 = newJObject()
  add(path_613811, "accountId", newJString(accountId))
  result = call_613810.call(path_613811, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_613798(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_613799,
                                      base: "/", url: url_GetAccount_613800,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_613828 = ref object of OpenApiRestCall_612658
proc url_DeleteAccount_613830(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccount_613829(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613831 = path.getOrDefault("accountId")
  valid_613831 = validateParameter(valid_613831, JString, required = true,
                                 default = nil)
  if valid_613831 != nil:
    section.add "accountId", valid_613831
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
  var valid_613832 = header.getOrDefault("X-Amz-Signature")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Signature", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Content-Sha256", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Date")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Date", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Credential")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Credential", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Security-Token")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Security-Token", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Algorithm")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Algorithm", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-SignedHeaders", valid_613838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613839: Call_DeleteAccount_613828; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_613839.validator(path, query, header, formData, body)
  let scheme = call_613839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613839.url(scheme.get, call_613839.host, call_613839.base,
                         call_613839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613839, url, valid)

proc call*(call_613840: Call_DeleteAccount_613828; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613841 = newJObject()
  add(path_613841, "accountId", newJString(accountId))
  result = call_613840.call(path_613841, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_613828(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_613829,
    base: "/", url: url_DeleteAccount_613830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttendee_613842 = ref object of OpenApiRestCall_612658
proc url_GetAttendee_613844(protocol: Scheme; host: string; base: string;
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

proc validate_GetAttendee_613843(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613845 = path.getOrDefault("attendeeId")
  valid_613845 = validateParameter(valid_613845, JString, required = true,
                                 default = nil)
  if valid_613845 != nil:
    section.add "attendeeId", valid_613845
  var valid_613846 = path.getOrDefault("meetingId")
  valid_613846 = validateParameter(valid_613846, JString, required = true,
                                 default = nil)
  if valid_613846 != nil:
    section.add "meetingId", valid_613846
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
  var valid_613847 = header.getOrDefault("X-Amz-Signature")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Signature", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Content-Sha256", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Date")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Date", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Credential")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Credential", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Security-Token")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Security-Token", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Algorithm")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Algorithm", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-SignedHeaders", valid_613853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613854: Call_GetAttendee_613842; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613854.validator(path, query, header, formData, body)
  let scheme = call_613854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613854.url(scheme.get, call_613854.host, call_613854.base,
                         call_613854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613854, url, valid)

proc call*(call_613855: Call_GetAttendee_613842; attendeeId: string;
          meetingId: string): Recallable =
  ## getAttendee
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_613856 = newJObject()
  add(path_613856, "attendeeId", newJString(attendeeId))
  add(path_613856, "meetingId", newJString(meetingId))
  result = call_613855.call(path_613856, nil, nil, nil, nil)

var getAttendee* = Call_GetAttendee_613842(name: "getAttendee",
                                        meth: HttpMethod.HttpGet,
                                        host: "chime.amazonaws.com", route: "/meetings/{meetingId}/attendees/{attendeeId}",
                                        validator: validate_GetAttendee_613843,
                                        base: "/", url: url_GetAttendee_613844,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttendee_613857 = ref object of OpenApiRestCall_612658
proc url_DeleteAttendee_613859(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAttendee_613858(path: JsonNode; query: JsonNode;
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
  var valid_613860 = path.getOrDefault("attendeeId")
  valid_613860 = validateParameter(valid_613860, JString, required = true,
                                 default = nil)
  if valid_613860 != nil:
    section.add "attendeeId", valid_613860
  var valid_613861 = path.getOrDefault("meetingId")
  valid_613861 = validateParameter(valid_613861, JString, required = true,
                                 default = nil)
  if valid_613861 != nil:
    section.add "meetingId", valid_613861
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
  var valid_613862 = header.getOrDefault("X-Amz-Signature")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Signature", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Content-Sha256", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Date")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Date", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Credential")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Credential", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Security-Token")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Security-Token", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Algorithm")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Algorithm", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-SignedHeaders", valid_613868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613869: Call_DeleteAttendee_613857; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613869.validator(path, query, header, formData, body)
  let scheme = call_613869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613869.url(scheme.get, call_613869.host, call_613869.base,
                         call_613869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613869, url, valid)

proc call*(call_613870: Call_DeleteAttendee_613857; attendeeId: string;
          meetingId: string): Recallable =
  ## deleteAttendee
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_613871 = newJObject()
  add(path_613871, "attendeeId", newJString(attendeeId))
  add(path_613871, "meetingId", newJString(meetingId))
  result = call_613870.call(path_613871, nil, nil, nil, nil)

var deleteAttendee* = Call_DeleteAttendee_613857(name: "deleteAttendee",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees/{attendeeId}",
    validator: validate_DeleteAttendee_613858, base: "/", url: url_DeleteAttendee_613859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_613887 = ref object of OpenApiRestCall_612658
proc url_PutEventsConfiguration_613889(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventsConfiguration_613888(path: JsonNode; query: JsonNode;
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
  var valid_613890 = path.getOrDefault("botId")
  valid_613890 = validateParameter(valid_613890, JString, required = true,
                                 default = nil)
  if valid_613890 != nil:
    section.add "botId", valid_613890
  var valid_613891 = path.getOrDefault("accountId")
  valid_613891 = validateParameter(valid_613891, JString, required = true,
                                 default = nil)
  if valid_613891 != nil:
    section.add "accountId", valid_613891
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
  var valid_613892 = header.getOrDefault("X-Amz-Signature")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Signature", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Content-Sha256", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Date")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Date", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Credential")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Credential", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Security-Token")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Security-Token", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Algorithm")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Algorithm", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-SignedHeaders", valid_613898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613900: Call_PutEventsConfiguration_613887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_613900.validator(path, query, header, formData, body)
  let scheme = call_613900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613900.url(scheme.get, call_613900.host, call_613900.base,
                         call_613900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613900, url, valid)

proc call*(call_613901: Call_PutEventsConfiguration_613887; botId: string;
          body: JsonNode; accountId: string): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613902 = newJObject()
  var body_613903 = newJObject()
  add(path_613902, "botId", newJString(botId))
  if body != nil:
    body_613903 = body
  add(path_613902, "accountId", newJString(accountId))
  result = call_613901.call(path_613902, nil, nil, nil, body_613903)

var putEventsConfiguration* = Call_PutEventsConfiguration_613887(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_613888, base: "/",
    url: url_PutEventsConfiguration_613889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_613872 = ref object of OpenApiRestCall_612658
proc url_GetEventsConfiguration_613874(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventsConfiguration_613873(path: JsonNode; query: JsonNode;
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
  var valid_613875 = path.getOrDefault("botId")
  valid_613875 = validateParameter(valid_613875, JString, required = true,
                                 default = nil)
  if valid_613875 != nil:
    section.add "botId", valid_613875
  var valid_613876 = path.getOrDefault("accountId")
  valid_613876 = validateParameter(valid_613876, JString, required = true,
                                 default = nil)
  if valid_613876 != nil:
    section.add "accountId", valid_613876
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
  var valid_613877 = header.getOrDefault("X-Amz-Signature")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Signature", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Content-Sha256", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Date")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Date", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Credential")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Credential", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Security-Token")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Security-Token", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Algorithm")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Algorithm", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-SignedHeaders", valid_613883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613884: Call_GetEventsConfiguration_613872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_613884.validator(path, query, header, formData, body)
  let scheme = call_613884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613884.url(scheme.get, call_613884.host, call_613884.base,
                         call_613884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613884, url, valid)

proc call*(call_613885: Call_GetEventsConfiguration_613872; botId: string;
          accountId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613886 = newJObject()
  add(path_613886, "botId", newJString(botId))
  add(path_613886, "accountId", newJString(accountId))
  result = call_613885.call(path_613886, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_613872(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_613873, base: "/",
    url: url_GetEventsConfiguration_613874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_613904 = ref object of OpenApiRestCall_612658
proc url_DeleteEventsConfiguration_613906(protocol: Scheme; host: string;
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

proc validate_DeleteEventsConfiguration_613905(path: JsonNode; query: JsonNode;
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
  var valid_613907 = path.getOrDefault("botId")
  valid_613907 = validateParameter(valid_613907, JString, required = true,
                                 default = nil)
  if valid_613907 != nil:
    section.add "botId", valid_613907
  var valid_613908 = path.getOrDefault("accountId")
  valid_613908 = validateParameter(valid_613908, JString, required = true,
                                 default = nil)
  if valid_613908 != nil:
    section.add "accountId", valid_613908
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
  var valid_613909 = header.getOrDefault("X-Amz-Signature")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Signature", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Content-Sha256", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Date")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Date", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Credential")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Credential", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Security-Token")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Security-Token", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Algorithm")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Algorithm", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-SignedHeaders", valid_613915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613916: Call_DeleteEventsConfiguration_613904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_613916.validator(path, query, header, formData, body)
  let scheme = call_613916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613916.url(scheme.get, call_613916.host, call_613916.base,
                         call_613916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613916, url, valid)

proc call*(call_613917: Call_DeleteEventsConfiguration_613904; botId: string;
          accountId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_613918 = newJObject()
  add(path_613918, "botId", newJString(botId))
  add(path_613918, "accountId", newJString(accountId))
  result = call_613917.call(path_613918, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_613904(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_613905, base: "/",
    url: url_DeleteEventsConfiguration_613906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMeeting_613919 = ref object of OpenApiRestCall_612658
proc url_GetMeeting_613921(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMeeting_613920(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613922 = path.getOrDefault("meetingId")
  valid_613922 = validateParameter(valid_613922, JString, required = true,
                                 default = nil)
  if valid_613922 != nil:
    section.add "meetingId", valid_613922
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
  var valid_613923 = header.getOrDefault("X-Amz-Signature")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Signature", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Content-Sha256", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Date")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Date", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Credential")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Credential", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Security-Token")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Security-Token", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Algorithm")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Algorithm", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-SignedHeaders", valid_613929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613930: Call_GetMeeting_613919; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613930.validator(path, query, header, formData, body)
  let scheme = call_613930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613930.url(scheme.get, call_613930.host, call_613930.base,
                         call_613930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613930, url, valid)

proc call*(call_613931: Call_GetMeeting_613919; meetingId: string): Recallable =
  ## getMeeting
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_613932 = newJObject()
  add(path_613932, "meetingId", newJString(meetingId))
  result = call_613931.call(path_613932, nil, nil, nil, nil)

var getMeeting* = Call_GetMeeting_613919(name: "getMeeting",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/meetings/{meetingId}",
                                      validator: validate_GetMeeting_613920,
                                      base: "/", url: url_GetMeeting_613921,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMeeting_613933 = ref object of OpenApiRestCall_612658
proc url_DeleteMeeting_613935(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMeeting_613934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613936 = path.getOrDefault("meetingId")
  valid_613936 = validateParameter(valid_613936, JString, required = true,
                                 default = nil)
  if valid_613936 != nil:
    section.add "meetingId", valid_613936
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
  var valid_613937 = header.getOrDefault("X-Amz-Signature")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Signature", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Content-Sha256", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-Date")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-Date", valid_613939
  var valid_613940 = header.getOrDefault("X-Amz-Credential")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Credential", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Security-Token")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Security-Token", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-Algorithm")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Algorithm", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-SignedHeaders", valid_613943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613944: Call_DeleteMeeting_613933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_613944.validator(path, query, header, formData, body)
  let scheme = call_613944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613944.url(scheme.get, call_613944.host, call_613944.base,
                         call_613944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613944, url, valid)

proc call*(call_613945: Call_DeleteMeeting_613933; meetingId: string): Recallable =
  ## deleteMeeting
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_613946 = newJObject()
  add(path_613946, "meetingId", newJString(meetingId))
  result = call_613945.call(path_613946, nil, nil, nil, nil)

var deleteMeeting* = Call_DeleteMeeting_613933(name: "deleteMeeting",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}", validator: validate_DeleteMeeting_613934,
    base: "/", url: url_DeleteMeeting_613935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_613961 = ref object of OpenApiRestCall_612658
proc url_UpdatePhoneNumber_613963(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePhoneNumber_613962(path: JsonNode; query: JsonNode;
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
  var valid_613964 = path.getOrDefault("phoneNumberId")
  valid_613964 = validateParameter(valid_613964, JString, required = true,
                                 default = nil)
  if valid_613964 != nil:
    section.add "phoneNumberId", valid_613964
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
  var valid_613965 = header.getOrDefault("X-Amz-Signature")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Signature", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Content-Sha256", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Date")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Date", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Credential")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Credential", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Security-Token")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Security-Token", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Algorithm")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Algorithm", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-SignedHeaders", valid_613971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613973: Call_UpdatePhoneNumber_613961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_613973.validator(path, query, header, formData, body)
  let scheme = call_613973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613973.url(scheme.get, call_613973.host, call_613973.base,
                         call_613973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613973, url, valid)

proc call*(call_613974: Call_UpdatePhoneNumber_613961; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_613975 = newJObject()
  var body_613976 = newJObject()
  add(path_613975, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_613976 = body
  result = call_613974.call(path_613975, nil, nil, nil, body_613976)

var updatePhoneNumber* = Call_UpdatePhoneNumber_613961(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_613962, base: "/",
    url: url_UpdatePhoneNumber_613963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_613947 = ref object of OpenApiRestCall_612658
proc url_GetPhoneNumber_613949(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumber_613948(path: JsonNode; query: JsonNode;
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
  var valid_613950 = path.getOrDefault("phoneNumberId")
  valid_613950 = validateParameter(valid_613950, JString, required = true,
                                 default = nil)
  if valid_613950 != nil:
    section.add "phoneNumberId", valid_613950
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
  var valid_613951 = header.getOrDefault("X-Amz-Signature")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Signature", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Content-Sha256", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Date")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Date", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Credential")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Credential", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Security-Token")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Security-Token", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-Algorithm")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Algorithm", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-SignedHeaders", valid_613957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613958: Call_GetPhoneNumber_613947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_613958.validator(path, query, header, formData, body)
  let scheme = call_613958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613958.url(scheme.get, call_613958.host, call_613958.base,
                         call_613958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613958, url, valid)

proc call*(call_613959: Call_GetPhoneNumber_613947; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_613960 = newJObject()
  add(path_613960, "phoneNumberId", newJString(phoneNumberId))
  result = call_613959.call(path_613960, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_613947(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_613948,
    base: "/", url: url_GetPhoneNumber_613949, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_613977 = ref object of OpenApiRestCall_612658
proc url_DeletePhoneNumber_613979(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePhoneNumber_613978(path: JsonNode; query: JsonNode;
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
  var valid_613980 = path.getOrDefault("phoneNumberId")
  valid_613980 = validateParameter(valid_613980, JString, required = true,
                                 default = nil)
  if valid_613980 != nil:
    section.add "phoneNumberId", valid_613980
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
  var valid_613981 = header.getOrDefault("X-Amz-Signature")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Signature", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Content-Sha256", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Date")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Date", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-Credential")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-Credential", valid_613984
  var valid_613985 = header.getOrDefault("X-Amz-Security-Token")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Security-Token", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-Algorithm")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Algorithm", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-SignedHeaders", valid_613987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613988: Call_DeletePhoneNumber_613977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_613988.validator(path, query, header, formData, body)
  let scheme = call_613988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613988.url(scheme.get, call_613988.host, call_613988.base,
                         call_613988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613988, url, valid)

proc call*(call_613989: Call_DeletePhoneNumber_613977; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_613990 = newJObject()
  add(path_613990, "phoneNumberId", newJString(phoneNumberId))
  result = call_613989.call(path_613990, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_613977(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_613978, base: "/",
    url: url_DeletePhoneNumber_613979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_614006 = ref object of OpenApiRestCall_612658
proc url_UpdateRoom_614008(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateRoom_614007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614009 = path.getOrDefault("accountId")
  valid_614009 = validateParameter(valid_614009, JString, required = true,
                                 default = nil)
  if valid_614009 != nil:
    section.add "accountId", valid_614009
  var valid_614010 = path.getOrDefault("roomId")
  valid_614010 = validateParameter(valid_614010, JString, required = true,
                                 default = nil)
  if valid_614010 != nil:
    section.add "roomId", valid_614010
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
  var valid_614011 = header.getOrDefault("X-Amz-Signature")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Signature", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Content-Sha256", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Date")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Date", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Credential")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Credential", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Security-Token")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Security-Token", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Algorithm")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Algorithm", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-SignedHeaders", valid_614017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614019: Call_UpdateRoom_614006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details, such as the room name.
  ## 
  let valid = call_614019.validator(path, query, header, formData, body)
  let scheme = call_614019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614019.url(scheme.get, call_614019.host, call_614019.base,
                         call_614019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614019, url, valid)

proc call*(call_614020: Call_UpdateRoom_614006; body: JsonNode; accountId: string;
          roomId: string): Recallable =
  ## updateRoom
  ## Updates room details, such as the room name.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_614021 = newJObject()
  var body_614022 = newJObject()
  if body != nil:
    body_614022 = body
  add(path_614021, "accountId", newJString(accountId))
  add(path_614021, "roomId", newJString(roomId))
  result = call_614020.call(path_614021, nil, nil, nil, body_614022)

var updateRoom* = Call_UpdateRoom_614006(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_UpdateRoom_614007,
                                      base: "/", url: url_UpdateRoom_614008,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_613991 = ref object of OpenApiRestCall_612658
proc url_GetRoom_613993(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoom_613992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613994 = path.getOrDefault("accountId")
  valid_613994 = validateParameter(valid_613994, JString, required = true,
                                 default = nil)
  if valid_613994 != nil:
    section.add "accountId", valid_613994
  var valid_613995 = path.getOrDefault("roomId")
  valid_613995 = validateParameter(valid_613995, JString, required = true,
                                 default = nil)
  if valid_613995 != nil:
    section.add "roomId", valid_613995
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
  var valid_613996 = header.getOrDefault("X-Amz-Signature")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Signature", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Content-Sha256", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Date")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Date", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Credential")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Credential", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-Security-Token")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Security-Token", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Algorithm")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Algorithm", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-SignedHeaders", valid_614002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614003: Call_GetRoom_613991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves room details, such as the room name.
  ## 
  let valid = call_614003.validator(path, query, header, formData, body)
  let scheme = call_614003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614003.url(scheme.get, call_614003.host, call_614003.base,
                         call_614003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614003, url, valid)

proc call*(call_614004: Call_GetRoom_613991; accountId: string; roomId: string): Recallable =
  ## getRoom
  ## Retrieves room details, such as the room name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_614005 = newJObject()
  add(path_614005, "accountId", newJString(accountId))
  add(path_614005, "roomId", newJString(roomId))
  result = call_614004.call(path_614005, nil, nil, nil, nil)

var getRoom* = Call_GetRoom_613991(name: "getRoom", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/rooms/{roomId}",
                                validator: validate_GetRoom_613992, base: "/",
                                url: url_GetRoom_613993,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_614023 = ref object of OpenApiRestCall_612658
proc url_DeleteRoom_614025(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteRoom_614024(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614026 = path.getOrDefault("accountId")
  valid_614026 = validateParameter(valid_614026, JString, required = true,
                                 default = nil)
  if valid_614026 != nil:
    section.add "accountId", valid_614026
  var valid_614027 = path.getOrDefault("roomId")
  valid_614027 = validateParameter(valid_614027, JString, required = true,
                                 default = nil)
  if valid_614027 != nil:
    section.add "roomId", valid_614027
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
  var valid_614028 = header.getOrDefault("X-Amz-Signature")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Signature", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Content-Sha256", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Date")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Date", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Credential")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Credential", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Security-Token")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Security-Token", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Algorithm")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Algorithm", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-SignedHeaders", valid_614034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614035: Call_DeleteRoom_614023; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a chat room.
  ## 
  let valid = call_614035.validator(path, query, header, formData, body)
  let scheme = call_614035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614035.url(scheme.get, call_614035.host, call_614035.base,
                         call_614035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614035, url, valid)

proc call*(call_614036: Call_DeleteRoom_614023; accountId: string; roomId: string): Recallable =
  ## deleteRoom
  ## Deletes a chat room.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The chat room ID.
  var path_614037 = newJObject()
  add(path_614037, "accountId", newJString(accountId))
  add(path_614037, "roomId", newJString(roomId))
  result = call_614036.call(path_614037, nil, nil, nil, nil)

var deleteRoom* = Call_DeleteRoom_614023(name: "deleteRoom",
                                      meth: HttpMethod.HttpDelete,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_DeleteRoom_614024,
                                      base: "/", url: url_DeleteRoom_614025,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoomMembership_614038 = ref object of OpenApiRestCall_612658
proc url_UpdateRoomMembership_614040(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoomMembership_614039(path: JsonNode; query: JsonNode;
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
  var valid_614041 = path.getOrDefault("memberId")
  valid_614041 = validateParameter(valid_614041, JString, required = true,
                                 default = nil)
  if valid_614041 != nil:
    section.add "memberId", valid_614041
  var valid_614042 = path.getOrDefault("accountId")
  valid_614042 = validateParameter(valid_614042, JString, required = true,
                                 default = nil)
  if valid_614042 != nil:
    section.add "accountId", valid_614042
  var valid_614043 = path.getOrDefault("roomId")
  valid_614043 = validateParameter(valid_614043, JString, required = true,
                                 default = nil)
  if valid_614043 != nil:
    section.add "roomId", valid_614043
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
  var valid_614044 = header.getOrDefault("X-Amz-Signature")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Signature", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Content-Sha256", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Date")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Date", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-Credential")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-Credential", valid_614047
  var valid_614048 = header.getOrDefault("X-Amz-Security-Token")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-Security-Token", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Algorithm")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Algorithm", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-SignedHeaders", valid_614050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614052: Call_UpdateRoomMembership_614038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room membership details, such as the member role. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ## 
  let valid = call_614052.validator(path, query, header, formData, body)
  let scheme = call_614052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614052.url(scheme.get, call_614052.host, call_614052.base,
                         call_614052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614052, url, valid)

proc call*(call_614053: Call_UpdateRoomMembership_614038; memberId: string;
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
  var path_614054 = newJObject()
  var body_614055 = newJObject()
  add(path_614054, "memberId", newJString(memberId))
  if body != nil:
    body_614055 = body
  add(path_614054, "accountId", newJString(accountId))
  add(path_614054, "roomId", newJString(roomId))
  result = call_614053.call(path_614054, nil, nil, nil, body_614055)

var updateRoomMembership* = Call_UpdateRoomMembership_614038(
    name: "updateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_UpdateRoomMembership_614039, base: "/",
    url: url_UpdateRoomMembership_614040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomMembership_614056 = ref object of OpenApiRestCall_612658
proc url_DeleteRoomMembership_614058(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoomMembership_614057(path: JsonNode; query: JsonNode;
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
  var valid_614059 = path.getOrDefault("memberId")
  valid_614059 = validateParameter(valid_614059, JString, required = true,
                                 default = nil)
  if valid_614059 != nil:
    section.add "memberId", valid_614059
  var valid_614060 = path.getOrDefault("accountId")
  valid_614060 = validateParameter(valid_614060, JString, required = true,
                                 default = nil)
  if valid_614060 != nil:
    section.add "accountId", valid_614060
  var valid_614061 = path.getOrDefault("roomId")
  valid_614061 = validateParameter(valid_614061, JString, required = true,
                                 default = nil)
  if valid_614061 != nil:
    section.add "roomId", valid_614061
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
  var valid_614062 = header.getOrDefault("X-Amz-Signature")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-Signature", valid_614062
  var valid_614063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Content-Sha256", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Date")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Date", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Credential")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Credential", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Security-Token")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Security-Token", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Algorithm")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Algorithm", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-SignedHeaders", valid_614068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614069: Call_DeleteRoomMembership_614056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a member from a chat room.
  ## 
  let valid = call_614069.validator(path, query, header, formData, body)
  let scheme = call_614069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614069.url(scheme.get, call_614069.host, call_614069.base,
                         call_614069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614069, url, valid)

proc call*(call_614070: Call_DeleteRoomMembership_614056; memberId: string;
          accountId: string; roomId: string): Recallable =
  ## deleteRoomMembership
  ## Removes a member from a chat room.
  ##   memberId: string (required)
  ##           : The member ID (user ID or bot ID).
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_614071 = newJObject()
  add(path_614071, "memberId", newJString(memberId))
  add(path_614071, "accountId", newJString(accountId))
  add(path_614071, "roomId", newJString(roomId))
  result = call_614070.call(path_614071, nil, nil, nil, nil)

var deleteRoomMembership* = Call_DeleteRoomMembership_614056(
    name: "deleteRoomMembership", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_DeleteRoomMembership_614057, base: "/",
    url: url_DeleteRoomMembership_614058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_614086 = ref object of OpenApiRestCall_612658
proc url_UpdateVoiceConnector_614088(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceConnector_614087(path: JsonNode; query: JsonNode;
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
  var valid_614089 = path.getOrDefault("voiceConnectorId")
  valid_614089 = validateParameter(valid_614089, JString, required = true,
                                 default = nil)
  if valid_614089 != nil:
    section.add "voiceConnectorId", valid_614089
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
  var valid_614090 = header.getOrDefault("X-Amz-Signature")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Signature", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Content-Sha256", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Date")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Date", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Credential")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Credential", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Security-Token")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Security-Token", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Algorithm")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Algorithm", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-SignedHeaders", valid_614096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614098: Call_UpdateVoiceConnector_614086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614098.validator(path, query, header, formData, body)
  let scheme = call_614098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614098.url(scheme.get, call_614098.host, call_614098.base,
                         call_614098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614098, url, valid)

proc call*(call_614099: Call_UpdateVoiceConnector_614086; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614100 = newJObject()
  var body_614101 = newJObject()
  add(path_614100, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614101 = body
  result = call_614099.call(path_614100, nil, nil, nil, body_614101)

var updateVoiceConnector* = Call_UpdateVoiceConnector_614086(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_614087, base: "/",
    url: url_UpdateVoiceConnector_614088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_614072 = ref object of OpenApiRestCall_612658
proc url_GetVoiceConnector_614074(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnector_614073(path: JsonNode; query: JsonNode;
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
  var valid_614075 = path.getOrDefault("voiceConnectorId")
  valid_614075 = validateParameter(valid_614075, JString, required = true,
                                 default = nil)
  if valid_614075 != nil:
    section.add "voiceConnectorId", valid_614075
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
  var valid_614076 = header.getOrDefault("X-Amz-Signature")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "X-Amz-Signature", valid_614076
  var valid_614077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "X-Amz-Content-Sha256", valid_614077
  var valid_614078 = header.getOrDefault("X-Amz-Date")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "X-Amz-Date", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Credential")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Credential", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Security-Token")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Security-Token", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-Algorithm")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-Algorithm", valid_614081
  var valid_614082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "X-Amz-SignedHeaders", valid_614082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614083: Call_GetVoiceConnector_614072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_614083.validator(path, query, header, formData, body)
  let scheme = call_614083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614083.url(scheme.get, call_614083.host, call_614083.base,
                         call_614083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614083, url, valid)

proc call*(call_614084: Call_GetVoiceConnector_614072; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614085 = newJObject()
  add(path_614085, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614084.call(path_614085, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_614072(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_614073, base: "/",
    url: url_GetVoiceConnector_614074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_614102 = ref object of OpenApiRestCall_612658
proc url_DeleteVoiceConnector_614104(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceConnector_614103(path: JsonNode; query: JsonNode;
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
  var valid_614105 = path.getOrDefault("voiceConnectorId")
  valid_614105 = validateParameter(valid_614105, JString, required = true,
                                 default = nil)
  if valid_614105 != nil:
    section.add "voiceConnectorId", valid_614105
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
  var valid_614106 = header.getOrDefault("X-Amz-Signature")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Signature", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Content-Sha256", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Date")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Date", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-Credential")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-Credential", valid_614109
  var valid_614110 = header.getOrDefault("X-Amz-Security-Token")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "X-Amz-Security-Token", valid_614110
  var valid_614111 = header.getOrDefault("X-Amz-Algorithm")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "X-Amz-Algorithm", valid_614111
  var valid_614112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-SignedHeaders", valid_614112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614113: Call_DeleteVoiceConnector_614102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  let valid = call_614113.validator(path, query, header, formData, body)
  let scheme = call_614113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614113.url(scheme.get, call_614113.host, call_614113.base,
                         call_614113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614113, url, valid)

proc call*(call_614114: Call_DeleteVoiceConnector_614102; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614115 = newJObject()
  add(path_614115, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614114.call(path_614115, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_614102(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_614103, base: "/",
    url: url_DeleteVoiceConnector_614104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnectorGroup_614130 = ref object of OpenApiRestCall_612658
proc url_UpdateVoiceConnectorGroup_614132(protocol: Scheme; host: string;
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

proc validate_UpdateVoiceConnectorGroup_614131(path: JsonNode; query: JsonNode;
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
  var valid_614133 = path.getOrDefault("voiceConnectorGroupId")
  valid_614133 = validateParameter(valid_614133, JString, required = true,
                                 default = nil)
  if valid_614133 != nil:
    section.add "voiceConnectorGroupId", valid_614133
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
  var valid_614134 = header.getOrDefault("X-Amz-Signature")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Signature", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Content-Sha256", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-Date")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-Date", valid_614136
  var valid_614137 = header.getOrDefault("X-Amz-Credential")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-Credential", valid_614137
  var valid_614138 = header.getOrDefault("X-Amz-Security-Token")
  valid_614138 = validateParameter(valid_614138, JString, required = false,
                                 default = nil)
  if valid_614138 != nil:
    section.add "X-Amz-Security-Token", valid_614138
  var valid_614139 = header.getOrDefault("X-Amz-Algorithm")
  valid_614139 = validateParameter(valid_614139, JString, required = false,
                                 default = nil)
  if valid_614139 != nil:
    section.add "X-Amz-Algorithm", valid_614139
  var valid_614140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-SignedHeaders", valid_614140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614142: Call_UpdateVoiceConnectorGroup_614130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  let valid = call_614142.validator(path, query, header, formData, body)
  let scheme = call_614142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614142.url(scheme.get, call_614142.host, call_614142.base,
                         call_614142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614142, url, valid)

proc call*(call_614143: Call_UpdateVoiceConnectorGroup_614130;
          voiceConnectorGroupId: string; body: JsonNode): Recallable =
  ## updateVoiceConnectorGroup
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   body: JObject (required)
  var path_614144 = newJObject()
  var body_614145 = newJObject()
  add(path_614144, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  if body != nil:
    body_614145 = body
  result = call_614143.call(path_614144, nil, nil, nil, body_614145)

var updateVoiceConnectorGroup* = Call_UpdateVoiceConnectorGroup_614130(
    name: "updateVoiceConnectorGroup", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_UpdateVoiceConnectorGroup_614131, base: "/",
    url: url_UpdateVoiceConnectorGroup_614132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorGroup_614116 = ref object of OpenApiRestCall_612658
proc url_GetVoiceConnectorGroup_614118(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnectorGroup_614117(path: JsonNode; query: JsonNode;
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
  var valid_614119 = path.getOrDefault("voiceConnectorGroupId")
  valid_614119 = validateParameter(valid_614119, JString, required = true,
                                 default = nil)
  if valid_614119 != nil:
    section.add "voiceConnectorGroupId", valid_614119
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
  var valid_614120 = header.getOrDefault("X-Amz-Signature")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "X-Amz-Signature", valid_614120
  var valid_614121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = nil)
  if valid_614121 != nil:
    section.add "X-Amz-Content-Sha256", valid_614121
  var valid_614122 = header.getOrDefault("X-Amz-Date")
  valid_614122 = validateParameter(valid_614122, JString, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "X-Amz-Date", valid_614122
  var valid_614123 = header.getOrDefault("X-Amz-Credential")
  valid_614123 = validateParameter(valid_614123, JString, required = false,
                                 default = nil)
  if valid_614123 != nil:
    section.add "X-Amz-Credential", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-Security-Token")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-Security-Token", valid_614124
  var valid_614125 = header.getOrDefault("X-Amz-Algorithm")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "X-Amz-Algorithm", valid_614125
  var valid_614126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-SignedHeaders", valid_614126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614127: Call_GetVoiceConnectorGroup_614116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  let valid = call_614127.validator(path, query, header, formData, body)
  let scheme = call_614127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614127.url(scheme.get, call_614127.host, call_614127.base,
                         call_614127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614127, url, valid)

proc call*(call_614128: Call_GetVoiceConnectorGroup_614116;
          voiceConnectorGroupId: string): Recallable =
  ## getVoiceConnectorGroup
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_614129 = newJObject()
  add(path_614129, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_614128.call(path_614129, nil, nil, nil, nil)

var getVoiceConnectorGroup* = Call_GetVoiceConnectorGroup_614116(
    name: "getVoiceConnectorGroup", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_GetVoiceConnectorGroup_614117, base: "/",
    url: url_GetVoiceConnectorGroup_614118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorGroup_614146 = ref object of OpenApiRestCall_612658
proc url_DeleteVoiceConnectorGroup_614148(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorGroup_614147(path: JsonNode; query: JsonNode;
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
  var valid_614149 = path.getOrDefault("voiceConnectorGroupId")
  valid_614149 = validateParameter(valid_614149, JString, required = true,
                                 default = nil)
  if valid_614149 != nil:
    section.add "voiceConnectorGroupId", valid_614149
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
  var valid_614150 = header.getOrDefault("X-Amz-Signature")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Signature", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Content-Sha256", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-Date")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-Date", valid_614152
  var valid_614153 = header.getOrDefault("X-Amz-Credential")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "X-Amz-Credential", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-Security-Token")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-Security-Token", valid_614154
  var valid_614155 = header.getOrDefault("X-Amz-Algorithm")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "X-Amz-Algorithm", valid_614155
  var valid_614156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614156 = validateParameter(valid_614156, JString, required = false,
                                 default = nil)
  if valid_614156 != nil:
    section.add "X-Amz-SignedHeaders", valid_614156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614157: Call_DeleteVoiceConnectorGroup_614146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  let valid = call_614157.validator(path, query, header, formData, body)
  let scheme = call_614157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614157.url(scheme.get, call_614157.host, call_614157.base,
                         call_614157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614157, url, valid)

proc call*(call_614158: Call_DeleteVoiceConnectorGroup_614146;
          voiceConnectorGroupId: string): Recallable =
  ## deleteVoiceConnectorGroup
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_614159 = newJObject()
  add(path_614159, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_614158.call(path_614159, nil, nil, nil, nil)

var deleteVoiceConnectorGroup* = Call_DeleteVoiceConnectorGroup_614146(
    name: "deleteVoiceConnectorGroup", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_DeleteVoiceConnectorGroup_614147, base: "/",
    url: url_DeleteVoiceConnectorGroup_614148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_614174 = ref object of OpenApiRestCall_612658
proc url_PutVoiceConnectorOrigination_614176(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorOrigination_614175(path: JsonNode; query: JsonNode;
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
  var valid_614177 = path.getOrDefault("voiceConnectorId")
  valid_614177 = validateParameter(valid_614177, JString, required = true,
                                 default = nil)
  if valid_614177 != nil:
    section.add "voiceConnectorId", valid_614177
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
  var valid_614178 = header.getOrDefault("X-Amz-Signature")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Signature", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Content-Sha256", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Date")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Date", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Credential")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Credential", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Security-Token")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Security-Token", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Algorithm")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Algorithm", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-SignedHeaders", valid_614184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614186: Call_PutVoiceConnectorOrigination_614174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614186.validator(path, query, header, formData, body)
  let scheme = call_614186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614186.url(scheme.get, call_614186.host, call_614186.base,
                         call_614186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614186, url, valid)

proc call*(call_614187: Call_PutVoiceConnectorOrigination_614174;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614188 = newJObject()
  var body_614189 = newJObject()
  add(path_614188, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614189 = body
  result = call_614187.call(path_614188, nil, nil, nil, body_614189)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_614174(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_614175, base: "/",
    url: url_PutVoiceConnectorOrigination_614176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_614160 = ref object of OpenApiRestCall_612658
proc url_GetVoiceConnectorOrigination_614162(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorOrigination_614161(path: JsonNode; query: JsonNode;
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
  var valid_614163 = path.getOrDefault("voiceConnectorId")
  valid_614163 = validateParameter(valid_614163, JString, required = true,
                                 default = nil)
  if valid_614163 != nil:
    section.add "voiceConnectorId", valid_614163
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
  var valid_614164 = header.getOrDefault("X-Amz-Signature")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Signature", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Content-Sha256", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Date")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Date", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Credential")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Credential", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-Security-Token")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-Security-Token", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-Algorithm")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-Algorithm", valid_614169
  var valid_614170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-SignedHeaders", valid_614170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614171: Call_GetVoiceConnectorOrigination_614160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614171.validator(path, query, header, formData, body)
  let scheme = call_614171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614171.url(scheme.get, call_614171.host, call_614171.base,
                         call_614171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614171, url, valid)

proc call*(call_614172: Call_GetVoiceConnectorOrigination_614160;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614173 = newJObject()
  add(path_614173, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614172.call(path_614173, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_614160(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_614161, base: "/",
    url: url_GetVoiceConnectorOrigination_614162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_614190 = ref object of OpenApiRestCall_612658
proc url_DeleteVoiceConnectorOrigination_614192(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorOrigination_614191(path: JsonNode;
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
  var valid_614193 = path.getOrDefault("voiceConnectorId")
  valid_614193 = validateParameter(valid_614193, JString, required = true,
                                 default = nil)
  if valid_614193 != nil:
    section.add "voiceConnectorId", valid_614193
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
  var valid_614194 = header.getOrDefault("X-Amz-Signature")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Signature", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Content-Sha256", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-Date")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-Date", valid_614196
  var valid_614197 = header.getOrDefault("X-Amz-Credential")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Credential", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Security-Token")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Security-Token", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Algorithm")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Algorithm", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-SignedHeaders", valid_614200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614201: Call_DeleteVoiceConnectorOrigination_614190;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614201.validator(path, query, header, formData, body)
  let scheme = call_614201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614201.url(scheme.get, call_614201.host, call_614201.base,
                         call_614201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614201, url, valid)

proc call*(call_614202: Call_DeleteVoiceConnectorOrigination_614190;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614203 = newJObject()
  add(path_614203, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614202.call(path_614203, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_614190(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_614191, base: "/",
    url: url_DeleteVoiceConnectorOrigination_614192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorStreamingConfiguration_614218 = ref object of OpenApiRestCall_612658
proc url_PutVoiceConnectorStreamingConfiguration_614220(protocol: Scheme;
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

proc validate_PutVoiceConnectorStreamingConfiguration_614219(path: JsonNode;
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
  var valid_614221 = path.getOrDefault("voiceConnectorId")
  valid_614221 = validateParameter(valid_614221, JString, required = true,
                                 default = nil)
  if valid_614221 != nil:
    section.add "voiceConnectorId", valid_614221
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
  var valid_614222 = header.getOrDefault("X-Amz-Signature")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Signature", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Content-Sha256", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-Date")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-Date", valid_614224
  var valid_614225 = header.getOrDefault("X-Amz-Credential")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-Credential", valid_614225
  var valid_614226 = header.getOrDefault("X-Amz-Security-Token")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-Security-Token", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-Algorithm")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Algorithm", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-SignedHeaders", valid_614228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614230: Call_PutVoiceConnectorStreamingConfiguration_614218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_614230.validator(path, query, header, formData, body)
  let scheme = call_614230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614230.url(scheme.get, call_614230.host, call_614230.base,
                         call_614230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614230, url, valid)

proc call*(call_614231: Call_PutVoiceConnectorStreamingConfiguration_614218;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorStreamingConfiguration
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614232 = newJObject()
  var body_614233 = newJObject()
  add(path_614232, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614233 = body
  result = call_614231.call(path_614232, nil, nil, nil, body_614233)

var putVoiceConnectorStreamingConfiguration* = Call_PutVoiceConnectorStreamingConfiguration_614218(
    name: "putVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_PutVoiceConnectorStreamingConfiguration_614219, base: "/",
    url: url_PutVoiceConnectorStreamingConfiguration_614220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorStreamingConfiguration_614204 = ref object of OpenApiRestCall_612658
proc url_GetVoiceConnectorStreamingConfiguration_614206(protocol: Scheme;
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

proc validate_GetVoiceConnectorStreamingConfiguration_614205(path: JsonNode;
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
  var valid_614207 = path.getOrDefault("voiceConnectorId")
  valid_614207 = validateParameter(valid_614207, JString, required = true,
                                 default = nil)
  if valid_614207 != nil:
    section.add "voiceConnectorId", valid_614207
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
  var valid_614208 = header.getOrDefault("X-Amz-Signature")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "X-Amz-Signature", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Content-Sha256", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-Date")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Date", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Credential")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Credential", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Security-Token")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Security-Token", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Algorithm")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Algorithm", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-SignedHeaders", valid_614214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614215: Call_GetVoiceConnectorStreamingConfiguration_614204;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_614215.validator(path, query, header, formData, body)
  let scheme = call_614215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614215.url(scheme.get, call_614215.host, call_614215.base,
                         call_614215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614215, url, valid)

proc call*(call_614216: Call_GetVoiceConnectorStreamingConfiguration_614204;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorStreamingConfiguration
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614217 = newJObject()
  add(path_614217, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614216.call(path_614217, nil, nil, nil, nil)

var getVoiceConnectorStreamingConfiguration* = Call_GetVoiceConnectorStreamingConfiguration_614204(
    name: "getVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_GetVoiceConnectorStreamingConfiguration_614205, base: "/",
    url: url_GetVoiceConnectorStreamingConfiguration_614206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorStreamingConfiguration_614234 = ref object of OpenApiRestCall_612658
proc url_DeleteVoiceConnectorStreamingConfiguration_614236(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorStreamingConfiguration_614235(path: JsonNode;
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
  var valid_614237 = path.getOrDefault("voiceConnectorId")
  valid_614237 = validateParameter(valid_614237, JString, required = true,
                                 default = nil)
  if valid_614237 != nil:
    section.add "voiceConnectorId", valid_614237
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
  var valid_614238 = header.getOrDefault("X-Amz-Signature")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "X-Amz-Signature", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-Content-Sha256", valid_614239
  var valid_614240 = header.getOrDefault("X-Amz-Date")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-Date", valid_614240
  var valid_614241 = header.getOrDefault("X-Amz-Credential")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "X-Amz-Credential", valid_614241
  var valid_614242 = header.getOrDefault("X-Amz-Security-Token")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-Security-Token", valid_614242
  var valid_614243 = header.getOrDefault("X-Amz-Algorithm")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-Algorithm", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-SignedHeaders", valid_614244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614245: Call_DeleteVoiceConnectorStreamingConfiguration_614234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614245.validator(path, query, header, formData, body)
  let scheme = call_614245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614245.url(scheme.get, call_614245.host, call_614245.base,
                         call_614245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614245, url, valid)

proc call*(call_614246: Call_DeleteVoiceConnectorStreamingConfiguration_614234;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorStreamingConfiguration
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614247 = newJObject()
  add(path_614247, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614246.call(path_614247, nil, nil, nil, nil)

var deleteVoiceConnectorStreamingConfiguration* = Call_DeleteVoiceConnectorStreamingConfiguration_614234(
    name: "deleteVoiceConnectorStreamingConfiguration",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_DeleteVoiceConnectorStreamingConfiguration_614235,
    base: "/", url: url_DeleteVoiceConnectorStreamingConfiguration_614236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_614262 = ref object of OpenApiRestCall_612658
proc url_PutVoiceConnectorTermination_614264(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorTermination_614263(path: JsonNode; query: JsonNode;
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
  var valid_614265 = path.getOrDefault("voiceConnectorId")
  valid_614265 = validateParameter(valid_614265, JString, required = true,
                                 default = nil)
  if valid_614265 != nil:
    section.add "voiceConnectorId", valid_614265
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
  var valid_614266 = header.getOrDefault("X-Amz-Signature")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Signature", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Content-Sha256", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-Date")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Date", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Credential")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Credential", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Security-Token")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Security-Token", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-Algorithm")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Algorithm", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-SignedHeaders", valid_614272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614274: Call_PutVoiceConnectorTermination_614262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614274.validator(path, query, header, formData, body)
  let scheme = call_614274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614274.url(scheme.get, call_614274.host, call_614274.base,
                         call_614274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614274, url, valid)

proc call*(call_614275: Call_PutVoiceConnectorTermination_614262;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614276 = newJObject()
  var body_614277 = newJObject()
  add(path_614276, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614277 = body
  result = call_614275.call(path_614276, nil, nil, nil, body_614277)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_614262(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_614263, base: "/",
    url: url_PutVoiceConnectorTermination_614264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_614248 = ref object of OpenApiRestCall_612658
proc url_GetVoiceConnectorTermination_614250(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTermination_614249(path: JsonNode; query: JsonNode;
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
  var valid_614251 = path.getOrDefault("voiceConnectorId")
  valid_614251 = validateParameter(valid_614251, JString, required = true,
                                 default = nil)
  if valid_614251 != nil:
    section.add "voiceConnectorId", valid_614251
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
  var valid_614252 = header.getOrDefault("X-Amz-Signature")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Signature", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Content-Sha256", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Date")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Date", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Credential")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Credential", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-Security-Token")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Security-Token", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-Algorithm")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Algorithm", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-SignedHeaders", valid_614258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614259: Call_GetVoiceConnectorTermination_614248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614259.validator(path, query, header, formData, body)
  let scheme = call_614259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614259.url(scheme.get, call_614259.host, call_614259.base,
                         call_614259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614259, url, valid)

proc call*(call_614260: Call_GetVoiceConnectorTermination_614248;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614261 = newJObject()
  add(path_614261, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614260.call(path_614261, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_614248(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_614249, base: "/",
    url: url_GetVoiceConnectorTermination_614250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_614278 = ref object of OpenApiRestCall_612658
proc url_DeleteVoiceConnectorTermination_614280(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorTermination_614279(path: JsonNode;
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
  var valid_614281 = path.getOrDefault("voiceConnectorId")
  valid_614281 = validateParameter(valid_614281, JString, required = true,
                                 default = nil)
  if valid_614281 != nil:
    section.add "voiceConnectorId", valid_614281
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
  var valid_614282 = header.getOrDefault("X-Amz-Signature")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "X-Amz-Signature", valid_614282
  var valid_614283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Content-Sha256", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Date")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Date", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-Credential")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-Credential", valid_614285
  var valid_614286 = header.getOrDefault("X-Amz-Security-Token")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Security-Token", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-Algorithm")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-Algorithm", valid_614287
  var valid_614288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614288 = validateParameter(valid_614288, JString, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "X-Amz-SignedHeaders", valid_614288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614289: Call_DeleteVoiceConnectorTermination_614278;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614289.validator(path, query, header, formData, body)
  let scheme = call_614289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614289.url(scheme.get, call_614289.host, call_614289.base,
                         call_614289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614289, url, valid)

proc call*(call_614290: Call_DeleteVoiceConnectorTermination_614278;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614291 = newJObject()
  add(path_614291, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614290.call(path_614291, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_614278(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_614279, base: "/",
    url: url_DeleteVoiceConnectorTermination_614280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_614292 = ref object of OpenApiRestCall_612658
proc url_DeleteVoiceConnectorTerminationCredentials_614294(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorTerminationCredentials_614293(path: JsonNode;
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
  var valid_614295 = path.getOrDefault("voiceConnectorId")
  valid_614295 = validateParameter(valid_614295, JString, required = true,
                                 default = nil)
  if valid_614295 != nil:
    section.add "voiceConnectorId", valid_614295
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614296 = query.getOrDefault("operation")
  valid_614296 = validateParameter(valid_614296, JString, required = true,
                                 default = newJString("delete"))
  if valid_614296 != nil:
    section.add "operation", valid_614296
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
  var valid_614297 = header.getOrDefault("X-Amz-Signature")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "X-Amz-Signature", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-Content-Sha256", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Date")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Date", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-Credential")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Credential", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Security-Token")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Security-Token", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Algorithm")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Algorithm", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-SignedHeaders", valid_614303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614305: Call_DeleteVoiceConnectorTerminationCredentials_614292;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_614305.validator(path, query, header, formData, body)
  let scheme = call_614305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614305.url(scheme.get, call_614305.host, call_614305.base,
                         call_614305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614305, url, valid)

proc call*(call_614306: Call_DeleteVoiceConnectorTerminationCredentials_614292;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614307 = newJObject()
  var query_614308 = newJObject()
  var body_614309 = newJObject()
  add(query_614308, "operation", newJString(operation))
  add(path_614307, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614309 = body
  result = call_614306.call(path_614307, query_614308, nil, nil, body_614309)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_614292(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_614293,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_614294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_614310 = ref object of OpenApiRestCall_612658
proc url_DisassociatePhoneNumberFromUser_614312(protocol: Scheme; host: string;
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

proc validate_DisassociatePhoneNumberFromUser_614311(path: JsonNode;
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
  var valid_614313 = path.getOrDefault("userId")
  valid_614313 = validateParameter(valid_614313, JString, required = true,
                                 default = nil)
  if valid_614313 != nil:
    section.add "userId", valid_614313
  var valid_614314 = path.getOrDefault("accountId")
  valid_614314 = validateParameter(valid_614314, JString, required = true,
                                 default = nil)
  if valid_614314 != nil:
    section.add "accountId", valid_614314
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614315 = query.getOrDefault("operation")
  valid_614315 = validateParameter(valid_614315, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_614315 != nil:
    section.add "operation", valid_614315
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
  var valid_614316 = header.getOrDefault("X-Amz-Signature")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Signature", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Content-Sha256", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Date")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Date", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Credential")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Credential", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Security-Token")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Security-Token", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Algorithm")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Algorithm", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-SignedHeaders", valid_614322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614323: Call_DisassociatePhoneNumberFromUser_614310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_614323.validator(path, query, header, formData, body)
  let scheme = call_614323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614323.url(scheme.get, call_614323.host, call_614323.base,
                         call_614323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614323, url, valid)

proc call*(call_614324: Call_DisassociatePhoneNumberFromUser_614310;
          userId: string; accountId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614325 = newJObject()
  var query_614326 = newJObject()
  add(query_614326, "operation", newJString(operation))
  add(path_614325, "userId", newJString(userId))
  add(path_614325, "accountId", newJString(accountId))
  result = call_614324.call(path_614325, query_614326, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_614310(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_614311, base: "/",
    url: url_DisassociatePhoneNumberFromUser_614312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_614327 = ref object of OpenApiRestCall_612658
proc url_DisassociatePhoneNumbersFromVoiceConnector_614329(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnector_614328(path: JsonNode;
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
  var valid_614330 = path.getOrDefault("voiceConnectorId")
  valid_614330 = validateParameter(valid_614330, JString, required = true,
                                 default = nil)
  if valid_614330 != nil:
    section.add "voiceConnectorId", valid_614330
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614331 = query.getOrDefault("operation")
  valid_614331 = validateParameter(valid_614331, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_614331 != nil:
    section.add "operation", valid_614331
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
  var valid_614332 = header.getOrDefault("X-Amz-Signature")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Signature", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Content-Sha256", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Date")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Date", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Credential")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Credential", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Security-Token")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Security-Token", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-Algorithm")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Algorithm", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-SignedHeaders", valid_614338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614340: Call_DisassociatePhoneNumbersFromVoiceConnector_614327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614340.validator(path, query, header, formData, body)
  let scheme = call_614340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614340.url(scheme.get, call_614340.host, call_614340.base,
                         call_614340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614340, url, valid)

proc call*(call_614341: Call_DisassociatePhoneNumbersFromVoiceConnector_614327;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614342 = newJObject()
  var query_614343 = newJObject()
  var body_614344 = newJObject()
  add(query_614343, "operation", newJString(operation))
  add(path_614342, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614344 = body
  result = call_614341.call(path_614342, query_614343, nil, nil, body_614344)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_614327(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_614328,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_614329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_614345 = ref object of OpenApiRestCall_612658
proc url_DisassociatePhoneNumbersFromVoiceConnectorGroup_614347(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_614346(
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
  var valid_614348 = path.getOrDefault("voiceConnectorGroupId")
  valid_614348 = validateParameter(valid_614348, JString, required = true,
                                 default = nil)
  if valid_614348 != nil:
    section.add "voiceConnectorGroupId", valid_614348
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614349 = query.getOrDefault("operation")
  valid_614349 = validateParameter(valid_614349, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_614349 != nil:
    section.add "operation", valid_614349
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
  var valid_614350 = header.getOrDefault("X-Amz-Signature")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Signature", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Content-Sha256", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-Date")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Date", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Credential")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Credential", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Security-Token")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Security-Token", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-Algorithm")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-Algorithm", valid_614355
  var valid_614356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "X-Amz-SignedHeaders", valid_614356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614358: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_614345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_614358.validator(path, query, header, formData, body)
  let scheme = call_614358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614358.url(scheme.get, call_614358.host, call_614358.base,
                         call_614358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614358, url, valid)

proc call*(call_614359: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_614345;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnectorGroup
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_614360 = newJObject()
  var query_614361 = newJObject()
  var body_614362 = newJObject()
  add(path_614360, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_614361, "operation", newJString(operation))
  if body != nil:
    body_614362 = body
  result = call_614359.call(path_614360, query_614361, nil, nil, body_614362)

var disassociatePhoneNumbersFromVoiceConnectorGroup* = Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_614345(
    name: "disassociatePhoneNumbersFromVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_614346,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnectorGroup_614347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSigninDelegateGroupsFromAccount_614363 = ref object of OpenApiRestCall_612658
proc url_DisassociateSigninDelegateGroupsFromAccount_614365(protocol: Scheme;
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

proc validate_DisassociateSigninDelegateGroupsFromAccount_614364(path: JsonNode;
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
  var valid_614366 = path.getOrDefault("accountId")
  valid_614366 = validateParameter(valid_614366, JString, required = true,
                                 default = nil)
  if valid_614366 != nil:
    section.add "accountId", valid_614366
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614367 = query.getOrDefault("operation")
  valid_614367 = validateParameter(valid_614367, JString, required = true, default = newJString(
      "disassociate-signin-delegate-groups"))
  if valid_614367 != nil:
    section.add "operation", valid_614367
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
  var valid_614368 = header.getOrDefault("X-Amz-Signature")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-Signature", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Content-Sha256", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-Date")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Date", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Credential")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Credential", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Security-Token")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Security-Token", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-Algorithm")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-Algorithm", valid_614373
  var valid_614374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-SignedHeaders", valid_614374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614376: Call_DisassociateSigninDelegateGroupsFromAccount_614363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ## 
  let valid = call_614376.validator(path, query, header, formData, body)
  let scheme = call_614376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614376.url(scheme.get, call_614376.host, call_614376.base,
                         call_614376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614376, url, valid)

proc call*(call_614377: Call_DisassociateSigninDelegateGroupsFromAccount_614363;
          body: JsonNode; accountId: string;
          operation: string = "disassociate-signin-delegate-groups"): Recallable =
  ## disassociateSigninDelegateGroupsFromAccount
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614378 = newJObject()
  var query_614379 = newJObject()
  var body_614380 = newJObject()
  add(query_614379, "operation", newJString(operation))
  if body != nil:
    body_614380 = body
  add(path_614378, "accountId", newJString(accountId))
  result = call_614377.call(path_614378, query_614379, nil, nil, body_614380)

var disassociateSigninDelegateGroupsFromAccount* = Call_DisassociateSigninDelegateGroupsFromAccount_614363(
    name: "disassociateSigninDelegateGroupsFromAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts/{accountId}#operation=disassociate-signin-delegate-groups",
    validator: validate_DisassociateSigninDelegateGroupsFromAccount_614364,
    base: "/", url: url_DisassociateSigninDelegateGroupsFromAccount_614365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_614395 = ref object of OpenApiRestCall_612658
proc url_UpdateAccountSettings_614397(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccountSettings_614396(path: JsonNode; query: JsonNode;
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
  var valid_614398 = path.getOrDefault("accountId")
  valid_614398 = validateParameter(valid_614398, JString, required = true,
                                 default = nil)
  if valid_614398 != nil:
    section.add "accountId", valid_614398
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
  var valid_614399 = header.getOrDefault("X-Amz-Signature")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "X-Amz-Signature", valid_614399
  var valid_614400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "X-Amz-Content-Sha256", valid_614400
  var valid_614401 = header.getOrDefault("X-Amz-Date")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "X-Amz-Date", valid_614401
  var valid_614402 = header.getOrDefault("X-Amz-Credential")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "X-Amz-Credential", valid_614402
  var valid_614403 = header.getOrDefault("X-Amz-Security-Token")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "X-Amz-Security-Token", valid_614403
  var valid_614404 = header.getOrDefault("X-Amz-Algorithm")
  valid_614404 = validateParameter(valid_614404, JString, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "X-Amz-Algorithm", valid_614404
  var valid_614405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-SignedHeaders", valid_614405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614407: Call_UpdateAccountSettings_614395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_614407.validator(path, query, header, formData, body)
  let scheme = call_614407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614407.url(scheme.get, call_614407.host, call_614407.base,
                         call_614407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614407, url, valid)

proc call*(call_614408: Call_UpdateAccountSettings_614395; body: JsonNode;
          accountId: string): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614409 = newJObject()
  var body_614410 = newJObject()
  if body != nil:
    body_614410 = body
  add(path_614409, "accountId", newJString(accountId))
  result = call_614408.call(path_614409, nil, nil, nil, body_614410)

var updateAccountSettings* = Call_UpdateAccountSettings_614395(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_614396, base: "/",
    url: url_UpdateAccountSettings_614397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_614381 = ref object of OpenApiRestCall_612658
proc url_GetAccountSettings_614383(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_614382(path: JsonNode; query: JsonNode;
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
  var valid_614384 = path.getOrDefault("accountId")
  valid_614384 = validateParameter(valid_614384, JString, required = true,
                                 default = nil)
  if valid_614384 != nil:
    section.add "accountId", valid_614384
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
  var valid_614385 = header.getOrDefault("X-Amz-Signature")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-Signature", valid_614385
  var valid_614386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614386 = validateParameter(valid_614386, JString, required = false,
                                 default = nil)
  if valid_614386 != nil:
    section.add "X-Amz-Content-Sha256", valid_614386
  var valid_614387 = header.getOrDefault("X-Amz-Date")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "X-Amz-Date", valid_614387
  var valid_614388 = header.getOrDefault("X-Amz-Credential")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Credential", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-Security-Token")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-Security-Token", valid_614389
  var valid_614390 = header.getOrDefault("X-Amz-Algorithm")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Algorithm", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-SignedHeaders", valid_614391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614392: Call_GetAccountSettings_614381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_614392.validator(path, query, header, formData, body)
  let scheme = call_614392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614392.url(scheme.get, call_614392.host, call_614392.base,
                         call_614392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614392, url, valid)

proc call*(call_614393: Call_GetAccountSettings_614381; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614394 = newJObject()
  add(path_614394, "accountId", newJString(accountId))
  result = call_614393.call(path_614394, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_614381(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_614382, base: "/",
    url: url_GetAccountSettings_614383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_614426 = ref object of OpenApiRestCall_612658
proc url_UpdateBot_614428(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateBot_614427(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614429 = path.getOrDefault("botId")
  valid_614429 = validateParameter(valid_614429, JString, required = true,
                                 default = nil)
  if valid_614429 != nil:
    section.add "botId", valid_614429
  var valid_614430 = path.getOrDefault("accountId")
  valid_614430 = validateParameter(valid_614430, JString, required = true,
                                 default = nil)
  if valid_614430 != nil:
    section.add "accountId", valid_614430
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
  var valid_614431 = header.getOrDefault("X-Amz-Signature")
  valid_614431 = validateParameter(valid_614431, JString, required = false,
                                 default = nil)
  if valid_614431 != nil:
    section.add "X-Amz-Signature", valid_614431
  var valid_614432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614432 = validateParameter(valid_614432, JString, required = false,
                                 default = nil)
  if valid_614432 != nil:
    section.add "X-Amz-Content-Sha256", valid_614432
  var valid_614433 = header.getOrDefault("X-Amz-Date")
  valid_614433 = validateParameter(valid_614433, JString, required = false,
                                 default = nil)
  if valid_614433 != nil:
    section.add "X-Amz-Date", valid_614433
  var valid_614434 = header.getOrDefault("X-Amz-Credential")
  valid_614434 = validateParameter(valid_614434, JString, required = false,
                                 default = nil)
  if valid_614434 != nil:
    section.add "X-Amz-Credential", valid_614434
  var valid_614435 = header.getOrDefault("X-Amz-Security-Token")
  valid_614435 = validateParameter(valid_614435, JString, required = false,
                                 default = nil)
  if valid_614435 != nil:
    section.add "X-Amz-Security-Token", valid_614435
  var valid_614436 = header.getOrDefault("X-Amz-Algorithm")
  valid_614436 = validateParameter(valid_614436, JString, required = false,
                                 default = nil)
  if valid_614436 != nil:
    section.add "X-Amz-Algorithm", valid_614436
  var valid_614437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-SignedHeaders", valid_614437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614439: Call_UpdateBot_614426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_614439.validator(path, query, header, formData, body)
  let scheme = call_614439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614439.url(scheme.get, call_614439.host, call_614439.base,
                         call_614439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614439, url, valid)

proc call*(call_614440: Call_UpdateBot_614426; botId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614441 = newJObject()
  var body_614442 = newJObject()
  add(path_614441, "botId", newJString(botId))
  if body != nil:
    body_614442 = body
  add(path_614441, "accountId", newJString(accountId))
  result = call_614440.call(path_614441, nil, nil, nil, body_614442)

var updateBot* = Call_UpdateBot_614426(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_614427,
                                    base: "/", url: url_UpdateBot_614428,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_614411 = ref object of OpenApiRestCall_612658
proc url_GetBot_614413(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_614412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614414 = path.getOrDefault("botId")
  valid_614414 = validateParameter(valid_614414, JString, required = true,
                                 default = nil)
  if valid_614414 != nil:
    section.add "botId", valid_614414
  var valid_614415 = path.getOrDefault("accountId")
  valid_614415 = validateParameter(valid_614415, JString, required = true,
                                 default = nil)
  if valid_614415 != nil:
    section.add "accountId", valid_614415
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
  var valid_614416 = header.getOrDefault("X-Amz-Signature")
  valid_614416 = validateParameter(valid_614416, JString, required = false,
                                 default = nil)
  if valid_614416 != nil:
    section.add "X-Amz-Signature", valid_614416
  var valid_614417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614417 = validateParameter(valid_614417, JString, required = false,
                                 default = nil)
  if valid_614417 != nil:
    section.add "X-Amz-Content-Sha256", valid_614417
  var valid_614418 = header.getOrDefault("X-Amz-Date")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "X-Amz-Date", valid_614418
  var valid_614419 = header.getOrDefault("X-Amz-Credential")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "X-Amz-Credential", valid_614419
  var valid_614420 = header.getOrDefault("X-Amz-Security-Token")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Security-Token", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Algorithm")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Algorithm", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-SignedHeaders", valid_614422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614423: Call_GetBot_614411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_614423.validator(path, query, header, formData, body)
  let scheme = call_614423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614423.url(scheme.get, call_614423.host, call_614423.base,
                         call_614423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614423, url, valid)

proc call*(call_614424: Call_GetBot_614411; botId: string; accountId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614425 = newJObject()
  add(path_614425, "botId", newJString(botId))
  add(path_614425, "accountId", newJString(accountId))
  result = call_614424.call(path_614425, nil, nil, nil, nil)

var getBot* = Call_GetBot_614411(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_614412, base: "/",
                              url: url_GetBot_614413,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_614455 = ref object of OpenApiRestCall_612658
proc url_UpdateGlobalSettings_614457(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGlobalSettings_614456(path: JsonNode; query: JsonNode;
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
  var valid_614458 = header.getOrDefault("X-Amz-Signature")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Signature", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Content-Sha256", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-Date")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-Date", valid_614460
  var valid_614461 = header.getOrDefault("X-Amz-Credential")
  valid_614461 = validateParameter(valid_614461, JString, required = false,
                                 default = nil)
  if valid_614461 != nil:
    section.add "X-Amz-Credential", valid_614461
  var valid_614462 = header.getOrDefault("X-Amz-Security-Token")
  valid_614462 = validateParameter(valid_614462, JString, required = false,
                                 default = nil)
  if valid_614462 != nil:
    section.add "X-Amz-Security-Token", valid_614462
  var valid_614463 = header.getOrDefault("X-Amz-Algorithm")
  valid_614463 = validateParameter(valid_614463, JString, required = false,
                                 default = nil)
  if valid_614463 != nil:
    section.add "X-Amz-Algorithm", valid_614463
  var valid_614464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614464 = validateParameter(valid_614464, JString, required = false,
                                 default = nil)
  if valid_614464 != nil:
    section.add "X-Amz-SignedHeaders", valid_614464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614466: Call_UpdateGlobalSettings_614455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_614466.validator(path, query, header, formData, body)
  let scheme = call_614466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614466.url(scheme.get, call_614466.host, call_614466.base,
                         call_614466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614466, url, valid)

proc call*(call_614467: Call_UpdateGlobalSettings_614455; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_614468 = newJObject()
  if body != nil:
    body_614468 = body
  result = call_614467.call(nil, nil, nil, nil, body_614468)

var updateGlobalSettings* = Call_UpdateGlobalSettings_614455(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_614456, base: "/",
    url: url_UpdateGlobalSettings_614457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_614443 = ref object of OpenApiRestCall_612658
proc url_GetGlobalSettings_614445(protocol: Scheme; host: string; base: string;
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

proc validate_GetGlobalSettings_614444(path: JsonNode; query: JsonNode;
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
  var valid_614446 = header.getOrDefault("X-Amz-Signature")
  valid_614446 = validateParameter(valid_614446, JString, required = false,
                                 default = nil)
  if valid_614446 != nil:
    section.add "X-Amz-Signature", valid_614446
  var valid_614447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614447 = validateParameter(valid_614447, JString, required = false,
                                 default = nil)
  if valid_614447 != nil:
    section.add "X-Amz-Content-Sha256", valid_614447
  var valid_614448 = header.getOrDefault("X-Amz-Date")
  valid_614448 = validateParameter(valid_614448, JString, required = false,
                                 default = nil)
  if valid_614448 != nil:
    section.add "X-Amz-Date", valid_614448
  var valid_614449 = header.getOrDefault("X-Amz-Credential")
  valid_614449 = validateParameter(valid_614449, JString, required = false,
                                 default = nil)
  if valid_614449 != nil:
    section.add "X-Amz-Credential", valid_614449
  var valid_614450 = header.getOrDefault("X-Amz-Security-Token")
  valid_614450 = validateParameter(valid_614450, JString, required = false,
                                 default = nil)
  if valid_614450 != nil:
    section.add "X-Amz-Security-Token", valid_614450
  var valid_614451 = header.getOrDefault("X-Amz-Algorithm")
  valid_614451 = validateParameter(valid_614451, JString, required = false,
                                 default = nil)
  if valid_614451 != nil:
    section.add "X-Amz-Algorithm", valid_614451
  var valid_614452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-SignedHeaders", valid_614452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614453: Call_GetGlobalSettings_614443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_614453.validator(path, query, header, formData, body)
  let scheme = call_614453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614453.url(scheme.get, call_614453.host, call_614453.base,
                         call_614453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614453, url, valid)

proc call*(call_614454: Call_GetGlobalSettings_614443): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_614454.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_614443(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_614444, base: "/",
    url: url_GetGlobalSettings_614445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_614469 = ref object of OpenApiRestCall_612658
proc url_GetPhoneNumberOrder_614471(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberOrder_614470(path: JsonNode; query: JsonNode;
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
  var valid_614472 = path.getOrDefault("phoneNumberOrderId")
  valid_614472 = validateParameter(valid_614472, JString, required = true,
                                 default = nil)
  if valid_614472 != nil:
    section.add "phoneNumberOrderId", valid_614472
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
  var valid_614473 = header.getOrDefault("X-Amz-Signature")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Signature", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Content-Sha256", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-Date")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-Date", valid_614475
  var valid_614476 = header.getOrDefault("X-Amz-Credential")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "X-Amz-Credential", valid_614476
  var valid_614477 = header.getOrDefault("X-Amz-Security-Token")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "X-Amz-Security-Token", valid_614477
  var valid_614478 = header.getOrDefault("X-Amz-Algorithm")
  valid_614478 = validateParameter(valid_614478, JString, required = false,
                                 default = nil)
  if valid_614478 != nil:
    section.add "X-Amz-Algorithm", valid_614478
  var valid_614479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614479 = validateParameter(valid_614479, JString, required = false,
                                 default = nil)
  if valid_614479 != nil:
    section.add "X-Amz-SignedHeaders", valid_614479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614480: Call_GetPhoneNumberOrder_614469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_614480.validator(path, query, header, formData, body)
  let scheme = call_614480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614480.url(scheme.get, call_614480.host, call_614480.base,
                         call_614480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614480, url, valid)

proc call*(call_614481: Call_GetPhoneNumberOrder_614469; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_614482 = newJObject()
  add(path_614482, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_614481.call(path_614482, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_614469(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_614470, base: "/",
    url: url_GetPhoneNumberOrder_614471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumberSettings_614495 = ref object of OpenApiRestCall_612658
proc url_UpdatePhoneNumberSettings_614497(protocol: Scheme; host: string;
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

proc validate_UpdatePhoneNumberSettings_614496(path: JsonNode; query: JsonNode;
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
  var valid_614498 = header.getOrDefault("X-Amz-Signature")
  valid_614498 = validateParameter(valid_614498, JString, required = false,
                                 default = nil)
  if valid_614498 != nil:
    section.add "X-Amz-Signature", valid_614498
  var valid_614499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614499 = validateParameter(valid_614499, JString, required = false,
                                 default = nil)
  if valid_614499 != nil:
    section.add "X-Amz-Content-Sha256", valid_614499
  var valid_614500 = header.getOrDefault("X-Amz-Date")
  valid_614500 = validateParameter(valid_614500, JString, required = false,
                                 default = nil)
  if valid_614500 != nil:
    section.add "X-Amz-Date", valid_614500
  var valid_614501 = header.getOrDefault("X-Amz-Credential")
  valid_614501 = validateParameter(valid_614501, JString, required = false,
                                 default = nil)
  if valid_614501 != nil:
    section.add "X-Amz-Credential", valid_614501
  var valid_614502 = header.getOrDefault("X-Amz-Security-Token")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "X-Amz-Security-Token", valid_614502
  var valid_614503 = header.getOrDefault("X-Amz-Algorithm")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "X-Amz-Algorithm", valid_614503
  var valid_614504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "X-Amz-SignedHeaders", valid_614504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614506: Call_UpdatePhoneNumberSettings_614495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ## 
  let valid = call_614506.validator(path, query, header, formData, body)
  let scheme = call_614506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614506.url(scheme.get, call_614506.host, call_614506.base,
                         call_614506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614506, url, valid)

proc call*(call_614507: Call_UpdatePhoneNumberSettings_614495; body: JsonNode): Recallable =
  ## updatePhoneNumberSettings
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ##   body: JObject (required)
  var body_614508 = newJObject()
  if body != nil:
    body_614508 = body
  result = call_614507.call(nil, nil, nil, nil, body_614508)

var updatePhoneNumberSettings* = Call_UpdatePhoneNumberSettings_614495(
    name: "updatePhoneNumberSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_UpdatePhoneNumberSettings_614496, base: "/",
    url: url_UpdatePhoneNumberSettings_614497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberSettings_614483 = ref object of OpenApiRestCall_612658
proc url_GetPhoneNumberSettings_614485(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberSettings_614484(path: JsonNode; query: JsonNode;
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
  var valid_614486 = header.getOrDefault("X-Amz-Signature")
  valid_614486 = validateParameter(valid_614486, JString, required = false,
                                 default = nil)
  if valid_614486 != nil:
    section.add "X-Amz-Signature", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Content-Sha256", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Date")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Date", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Credential")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Credential", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Security-Token")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Security-Token", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-Algorithm")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Algorithm", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-SignedHeaders", valid_614492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614493: Call_GetPhoneNumberSettings_614483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  let valid = call_614493.validator(path, query, header, formData, body)
  let scheme = call_614493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614493.url(scheme.get, call_614493.host, call_614493.base,
                         call_614493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614493, url, valid)

proc call*(call_614494: Call_GetPhoneNumberSettings_614483): Recallable =
  ## getPhoneNumberSettings
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  result = call_614494.call(nil, nil, nil, nil, nil)

var getPhoneNumberSettings* = Call_GetPhoneNumberSettings_614483(
    name: "getPhoneNumberSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_GetPhoneNumberSettings_614484, base: "/",
    url: url_GetPhoneNumberSettings_614485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_614524 = ref object of OpenApiRestCall_612658
proc url_UpdateUser_614526(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_614525(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614527 = path.getOrDefault("userId")
  valid_614527 = validateParameter(valid_614527, JString, required = true,
                                 default = nil)
  if valid_614527 != nil:
    section.add "userId", valid_614527
  var valid_614528 = path.getOrDefault("accountId")
  valid_614528 = validateParameter(valid_614528, JString, required = true,
                                 default = nil)
  if valid_614528 != nil:
    section.add "accountId", valid_614528
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
  var valid_614529 = header.getOrDefault("X-Amz-Signature")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "X-Amz-Signature", valid_614529
  var valid_614530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614530 = validateParameter(valid_614530, JString, required = false,
                                 default = nil)
  if valid_614530 != nil:
    section.add "X-Amz-Content-Sha256", valid_614530
  var valid_614531 = header.getOrDefault("X-Amz-Date")
  valid_614531 = validateParameter(valid_614531, JString, required = false,
                                 default = nil)
  if valid_614531 != nil:
    section.add "X-Amz-Date", valid_614531
  var valid_614532 = header.getOrDefault("X-Amz-Credential")
  valid_614532 = validateParameter(valid_614532, JString, required = false,
                                 default = nil)
  if valid_614532 != nil:
    section.add "X-Amz-Credential", valid_614532
  var valid_614533 = header.getOrDefault("X-Amz-Security-Token")
  valid_614533 = validateParameter(valid_614533, JString, required = false,
                                 default = nil)
  if valid_614533 != nil:
    section.add "X-Amz-Security-Token", valid_614533
  var valid_614534 = header.getOrDefault("X-Amz-Algorithm")
  valid_614534 = validateParameter(valid_614534, JString, required = false,
                                 default = nil)
  if valid_614534 != nil:
    section.add "X-Amz-Algorithm", valid_614534
  var valid_614535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "X-Amz-SignedHeaders", valid_614535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614537: Call_UpdateUser_614524; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_614537.validator(path, query, header, formData, body)
  let scheme = call_614537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614537.url(scheme.get, call_614537.host, call_614537.base,
                         call_614537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614537, url, valid)

proc call*(call_614538: Call_UpdateUser_614524; userId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614539 = newJObject()
  var body_614540 = newJObject()
  add(path_614539, "userId", newJString(userId))
  if body != nil:
    body_614540 = body
  add(path_614539, "accountId", newJString(accountId))
  result = call_614538.call(path_614539, nil, nil, nil, body_614540)

var updateUser* = Call_UpdateUser_614524(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_614525,
                                      base: "/", url: url_UpdateUser_614526,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_614509 = ref object of OpenApiRestCall_612658
proc url_GetUser_614511(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_614510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614512 = path.getOrDefault("userId")
  valid_614512 = validateParameter(valid_614512, JString, required = true,
                                 default = nil)
  if valid_614512 != nil:
    section.add "userId", valid_614512
  var valid_614513 = path.getOrDefault("accountId")
  valid_614513 = validateParameter(valid_614513, JString, required = true,
                                 default = nil)
  if valid_614513 != nil:
    section.add "accountId", valid_614513
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
  var valid_614514 = header.getOrDefault("X-Amz-Signature")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "X-Amz-Signature", valid_614514
  var valid_614515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "X-Amz-Content-Sha256", valid_614515
  var valid_614516 = header.getOrDefault("X-Amz-Date")
  valid_614516 = validateParameter(valid_614516, JString, required = false,
                                 default = nil)
  if valid_614516 != nil:
    section.add "X-Amz-Date", valid_614516
  var valid_614517 = header.getOrDefault("X-Amz-Credential")
  valid_614517 = validateParameter(valid_614517, JString, required = false,
                                 default = nil)
  if valid_614517 != nil:
    section.add "X-Amz-Credential", valid_614517
  var valid_614518 = header.getOrDefault("X-Amz-Security-Token")
  valid_614518 = validateParameter(valid_614518, JString, required = false,
                                 default = nil)
  if valid_614518 != nil:
    section.add "X-Amz-Security-Token", valid_614518
  var valid_614519 = header.getOrDefault("X-Amz-Algorithm")
  valid_614519 = validateParameter(valid_614519, JString, required = false,
                                 default = nil)
  if valid_614519 != nil:
    section.add "X-Amz-Algorithm", valid_614519
  var valid_614520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "X-Amz-SignedHeaders", valid_614520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614521: Call_GetUser_614509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_614521.validator(path, query, header, formData, body)
  let scheme = call_614521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614521.url(scheme.get, call_614521.host, call_614521.base,
                         call_614521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614521, url, valid)

proc call*(call_614522: Call_GetUser_614509; userId: string; accountId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614523 = newJObject()
  add(path_614523, "userId", newJString(userId))
  add(path_614523, "accountId", newJString(accountId))
  result = call_614522.call(path_614523, nil, nil, nil, nil)

var getUser* = Call_GetUser_614509(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_614510, base: "/",
                                url: url_GetUser_614511,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_614556 = ref object of OpenApiRestCall_612658
proc url_UpdateUserSettings_614558(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserSettings_614557(path: JsonNode; query: JsonNode;
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
  var valid_614559 = path.getOrDefault("userId")
  valid_614559 = validateParameter(valid_614559, JString, required = true,
                                 default = nil)
  if valid_614559 != nil:
    section.add "userId", valid_614559
  var valid_614560 = path.getOrDefault("accountId")
  valid_614560 = validateParameter(valid_614560, JString, required = true,
                                 default = nil)
  if valid_614560 != nil:
    section.add "accountId", valid_614560
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
  var valid_614561 = header.getOrDefault("X-Amz-Signature")
  valid_614561 = validateParameter(valid_614561, JString, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "X-Amz-Signature", valid_614561
  var valid_614562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "X-Amz-Content-Sha256", valid_614562
  var valid_614563 = header.getOrDefault("X-Amz-Date")
  valid_614563 = validateParameter(valid_614563, JString, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "X-Amz-Date", valid_614563
  var valid_614564 = header.getOrDefault("X-Amz-Credential")
  valid_614564 = validateParameter(valid_614564, JString, required = false,
                                 default = nil)
  if valid_614564 != nil:
    section.add "X-Amz-Credential", valid_614564
  var valid_614565 = header.getOrDefault("X-Amz-Security-Token")
  valid_614565 = validateParameter(valid_614565, JString, required = false,
                                 default = nil)
  if valid_614565 != nil:
    section.add "X-Amz-Security-Token", valid_614565
  var valid_614566 = header.getOrDefault("X-Amz-Algorithm")
  valid_614566 = validateParameter(valid_614566, JString, required = false,
                                 default = nil)
  if valid_614566 != nil:
    section.add "X-Amz-Algorithm", valid_614566
  var valid_614567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614567 = validateParameter(valid_614567, JString, required = false,
                                 default = nil)
  if valid_614567 != nil:
    section.add "X-Amz-SignedHeaders", valid_614567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614569: Call_UpdateUserSettings_614556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_614569.validator(path, query, header, formData, body)
  let scheme = call_614569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614569.url(scheme.get, call_614569.host, call_614569.base,
                         call_614569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614569, url, valid)

proc call*(call_614570: Call_UpdateUserSettings_614556; userId: string;
          body: JsonNode; accountId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614571 = newJObject()
  var body_614572 = newJObject()
  add(path_614571, "userId", newJString(userId))
  if body != nil:
    body_614572 = body
  add(path_614571, "accountId", newJString(accountId))
  result = call_614570.call(path_614571, nil, nil, nil, body_614572)

var updateUserSettings* = Call_UpdateUserSettings_614556(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_614557, base: "/",
    url: url_UpdateUserSettings_614558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_614541 = ref object of OpenApiRestCall_612658
proc url_GetUserSettings_614543(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserSettings_614542(path: JsonNode; query: JsonNode;
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
  var valid_614544 = path.getOrDefault("userId")
  valid_614544 = validateParameter(valid_614544, JString, required = true,
                                 default = nil)
  if valid_614544 != nil:
    section.add "userId", valid_614544
  var valid_614545 = path.getOrDefault("accountId")
  valid_614545 = validateParameter(valid_614545, JString, required = true,
                                 default = nil)
  if valid_614545 != nil:
    section.add "accountId", valid_614545
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
  var valid_614546 = header.getOrDefault("X-Amz-Signature")
  valid_614546 = validateParameter(valid_614546, JString, required = false,
                                 default = nil)
  if valid_614546 != nil:
    section.add "X-Amz-Signature", valid_614546
  var valid_614547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614547 = validateParameter(valid_614547, JString, required = false,
                                 default = nil)
  if valid_614547 != nil:
    section.add "X-Amz-Content-Sha256", valid_614547
  var valid_614548 = header.getOrDefault("X-Amz-Date")
  valid_614548 = validateParameter(valid_614548, JString, required = false,
                                 default = nil)
  if valid_614548 != nil:
    section.add "X-Amz-Date", valid_614548
  var valid_614549 = header.getOrDefault("X-Amz-Credential")
  valid_614549 = validateParameter(valid_614549, JString, required = false,
                                 default = nil)
  if valid_614549 != nil:
    section.add "X-Amz-Credential", valid_614549
  var valid_614550 = header.getOrDefault("X-Amz-Security-Token")
  valid_614550 = validateParameter(valid_614550, JString, required = false,
                                 default = nil)
  if valid_614550 != nil:
    section.add "X-Amz-Security-Token", valid_614550
  var valid_614551 = header.getOrDefault("X-Amz-Algorithm")
  valid_614551 = validateParameter(valid_614551, JString, required = false,
                                 default = nil)
  if valid_614551 != nil:
    section.add "X-Amz-Algorithm", valid_614551
  var valid_614552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614552 = validateParameter(valid_614552, JString, required = false,
                                 default = nil)
  if valid_614552 != nil:
    section.add "X-Amz-SignedHeaders", valid_614552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614553: Call_GetUserSettings_614541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_614553.validator(path, query, header, formData, body)
  let scheme = call_614553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614553.url(scheme.get, call_614553.host, call_614553.base,
                         call_614553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614553, url, valid)

proc call*(call_614554: Call_GetUserSettings_614541; userId: string;
          accountId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614555 = newJObject()
  add(path_614555, "userId", newJString(userId))
  add(path_614555, "accountId", newJString(accountId))
  result = call_614554.call(path_614555, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_614541(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_614542, base: "/", url: url_GetUserSettings_614543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorLoggingConfiguration_614587 = ref object of OpenApiRestCall_612658
proc url_PutVoiceConnectorLoggingConfiguration_614589(protocol: Scheme;
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

proc validate_PutVoiceConnectorLoggingConfiguration_614588(path: JsonNode;
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
  var valid_614590 = path.getOrDefault("voiceConnectorId")
  valid_614590 = validateParameter(valid_614590, JString, required = true,
                                 default = nil)
  if valid_614590 != nil:
    section.add "voiceConnectorId", valid_614590
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
  var valid_614591 = header.getOrDefault("X-Amz-Signature")
  valid_614591 = validateParameter(valid_614591, JString, required = false,
                                 default = nil)
  if valid_614591 != nil:
    section.add "X-Amz-Signature", valid_614591
  var valid_614592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614592 = validateParameter(valid_614592, JString, required = false,
                                 default = nil)
  if valid_614592 != nil:
    section.add "X-Amz-Content-Sha256", valid_614592
  var valid_614593 = header.getOrDefault("X-Amz-Date")
  valid_614593 = validateParameter(valid_614593, JString, required = false,
                                 default = nil)
  if valid_614593 != nil:
    section.add "X-Amz-Date", valid_614593
  var valid_614594 = header.getOrDefault("X-Amz-Credential")
  valid_614594 = validateParameter(valid_614594, JString, required = false,
                                 default = nil)
  if valid_614594 != nil:
    section.add "X-Amz-Credential", valid_614594
  var valid_614595 = header.getOrDefault("X-Amz-Security-Token")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-Security-Token", valid_614595
  var valid_614596 = header.getOrDefault("X-Amz-Algorithm")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Algorithm", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-SignedHeaders", valid_614597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614599: Call_PutVoiceConnectorLoggingConfiguration_614587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_614599.validator(path, query, header, formData, body)
  let scheme = call_614599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614599.url(scheme.get, call_614599.host, call_614599.base,
                         call_614599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614599, url, valid)

proc call*(call_614600: Call_PutVoiceConnectorLoggingConfiguration_614587;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorLoggingConfiguration
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614601 = newJObject()
  var body_614602 = newJObject()
  add(path_614601, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614602 = body
  result = call_614600.call(path_614601, nil, nil, nil, body_614602)

var putVoiceConnectorLoggingConfiguration* = Call_PutVoiceConnectorLoggingConfiguration_614587(
    name: "putVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_PutVoiceConnectorLoggingConfiguration_614588, base: "/",
    url: url_PutVoiceConnectorLoggingConfiguration_614589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorLoggingConfiguration_614573 = ref object of OpenApiRestCall_612658
proc url_GetVoiceConnectorLoggingConfiguration_614575(protocol: Scheme;
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

proc validate_GetVoiceConnectorLoggingConfiguration_614574(path: JsonNode;
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
  var valid_614576 = path.getOrDefault("voiceConnectorId")
  valid_614576 = validateParameter(valid_614576, JString, required = true,
                                 default = nil)
  if valid_614576 != nil:
    section.add "voiceConnectorId", valid_614576
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
  var valid_614577 = header.getOrDefault("X-Amz-Signature")
  valid_614577 = validateParameter(valid_614577, JString, required = false,
                                 default = nil)
  if valid_614577 != nil:
    section.add "X-Amz-Signature", valid_614577
  var valid_614578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614578 = validateParameter(valid_614578, JString, required = false,
                                 default = nil)
  if valid_614578 != nil:
    section.add "X-Amz-Content-Sha256", valid_614578
  var valid_614579 = header.getOrDefault("X-Amz-Date")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "X-Amz-Date", valid_614579
  var valid_614580 = header.getOrDefault("X-Amz-Credential")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-Credential", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Security-Token")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Security-Token", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Algorithm")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Algorithm", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-SignedHeaders", valid_614583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614584: Call_GetVoiceConnectorLoggingConfiguration_614573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_614584.validator(path, query, header, formData, body)
  let scheme = call_614584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614584.url(scheme.get, call_614584.host, call_614584.base,
                         call_614584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614584, url, valid)

proc call*(call_614585: Call_GetVoiceConnectorLoggingConfiguration_614573;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorLoggingConfiguration
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614586 = newJObject()
  add(path_614586, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614585.call(path_614586, nil, nil, nil, nil)

var getVoiceConnectorLoggingConfiguration* = Call_GetVoiceConnectorLoggingConfiguration_614573(
    name: "getVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_GetVoiceConnectorLoggingConfiguration_614574, base: "/",
    url: url_GetVoiceConnectorLoggingConfiguration_614575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_614603 = ref object of OpenApiRestCall_612658
proc url_GetVoiceConnectorTerminationHealth_614605(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTerminationHealth_614604(path: JsonNode;
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
  var valid_614606 = path.getOrDefault("voiceConnectorId")
  valid_614606 = validateParameter(valid_614606, JString, required = true,
                                 default = nil)
  if valid_614606 != nil:
    section.add "voiceConnectorId", valid_614606
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
  var valid_614607 = header.getOrDefault("X-Amz-Signature")
  valid_614607 = validateParameter(valid_614607, JString, required = false,
                                 default = nil)
  if valid_614607 != nil:
    section.add "X-Amz-Signature", valid_614607
  var valid_614608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "X-Amz-Content-Sha256", valid_614608
  var valid_614609 = header.getOrDefault("X-Amz-Date")
  valid_614609 = validateParameter(valid_614609, JString, required = false,
                                 default = nil)
  if valid_614609 != nil:
    section.add "X-Amz-Date", valid_614609
  var valid_614610 = header.getOrDefault("X-Amz-Credential")
  valid_614610 = validateParameter(valid_614610, JString, required = false,
                                 default = nil)
  if valid_614610 != nil:
    section.add "X-Amz-Credential", valid_614610
  var valid_614611 = header.getOrDefault("X-Amz-Security-Token")
  valid_614611 = validateParameter(valid_614611, JString, required = false,
                                 default = nil)
  if valid_614611 != nil:
    section.add "X-Amz-Security-Token", valid_614611
  var valid_614612 = header.getOrDefault("X-Amz-Algorithm")
  valid_614612 = validateParameter(valid_614612, JString, required = false,
                                 default = nil)
  if valid_614612 != nil:
    section.add "X-Amz-Algorithm", valid_614612
  var valid_614613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614613 = validateParameter(valid_614613, JString, required = false,
                                 default = nil)
  if valid_614613 != nil:
    section.add "X-Amz-SignedHeaders", valid_614613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614614: Call_GetVoiceConnectorTerminationHealth_614603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614614.validator(path, query, header, formData, body)
  let scheme = call_614614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614614.url(scheme.get, call_614614.host, call_614614.base,
                         call_614614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614614, url, valid)

proc call*(call_614615: Call_GetVoiceConnectorTerminationHealth_614603;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614616 = newJObject()
  add(path_614616, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614615.call(path_614616, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_614603(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_614604, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_614605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_614617 = ref object of OpenApiRestCall_612658
proc url_InviteUsers_614619(protocol: Scheme; host: string; base: string;
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

proc validate_InviteUsers_614618(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614620 = path.getOrDefault("accountId")
  valid_614620 = validateParameter(valid_614620, JString, required = true,
                                 default = nil)
  if valid_614620 != nil:
    section.add "accountId", valid_614620
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614621 = query.getOrDefault("operation")
  valid_614621 = validateParameter(valid_614621, JString, required = true,
                                 default = newJString("add"))
  if valid_614621 != nil:
    section.add "operation", valid_614621
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
  var valid_614622 = header.getOrDefault("X-Amz-Signature")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-Signature", valid_614622
  var valid_614623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "X-Amz-Content-Sha256", valid_614623
  var valid_614624 = header.getOrDefault("X-Amz-Date")
  valid_614624 = validateParameter(valid_614624, JString, required = false,
                                 default = nil)
  if valid_614624 != nil:
    section.add "X-Amz-Date", valid_614624
  var valid_614625 = header.getOrDefault("X-Amz-Credential")
  valid_614625 = validateParameter(valid_614625, JString, required = false,
                                 default = nil)
  if valid_614625 != nil:
    section.add "X-Amz-Credential", valid_614625
  var valid_614626 = header.getOrDefault("X-Amz-Security-Token")
  valid_614626 = validateParameter(valid_614626, JString, required = false,
                                 default = nil)
  if valid_614626 != nil:
    section.add "X-Amz-Security-Token", valid_614626
  var valid_614627 = header.getOrDefault("X-Amz-Algorithm")
  valid_614627 = validateParameter(valid_614627, JString, required = false,
                                 default = nil)
  if valid_614627 != nil:
    section.add "X-Amz-Algorithm", valid_614627
  var valid_614628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614628 = validateParameter(valid_614628, JString, required = false,
                                 default = nil)
  if valid_614628 != nil:
    section.add "X-Amz-SignedHeaders", valid_614628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614630: Call_InviteUsers_614617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_614630.validator(path, query, header, formData, body)
  let scheme = call_614630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614630.url(scheme.get, call_614630.host, call_614630.base,
                         call_614630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614630, url, valid)

proc call*(call_614631: Call_InviteUsers_614617; body: JsonNode; accountId: string;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614632 = newJObject()
  var query_614633 = newJObject()
  var body_614634 = newJObject()
  add(query_614633, "operation", newJString(operation))
  if body != nil:
    body_614634 = body
  add(path_614632, "accountId", newJString(accountId))
  result = call_614631.call(path_614632, query_614633, nil, nil, body_614634)

var inviteUsers* = Call_InviteUsers_614617(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_614618,
                                        base: "/", url: url_InviteUsers_614619,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_614635 = ref object of OpenApiRestCall_612658
proc url_ListPhoneNumbers_614637(protocol: Scheme; host: string; base: string;
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

proc validate_ListPhoneNumbers_614636(path: JsonNode; query: JsonNode;
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
  var valid_614638 = query.getOrDefault("MaxResults")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "MaxResults", valid_614638
  var valid_614639 = query.getOrDefault("NextToken")
  valid_614639 = validateParameter(valid_614639, JString, required = false,
                                 default = nil)
  if valid_614639 != nil:
    section.add "NextToken", valid_614639
  var valid_614640 = query.getOrDefault("product-type")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_614640 != nil:
    section.add "product-type", valid_614640
  var valid_614641 = query.getOrDefault("filter-name")
  valid_614641 = validateParameter(valid_614641, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_614641 != nil:
    section.add "filter-name", valid_614641
  var valid_614642 = query.getOrDefault("max-results")
  valid_614642 = validateParameter(valid_614642, JInt, required = false, default = nil)
  if valid_614642 != nil:
    section.add "max-results", valid_614642
  var valid_614643 = query.getOrDefault("status")
  valid_614643 = validateParameter(valid_614643, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_614643 != nil:
    section.add "status", valid_614643
  var valid_614644 = query.getOrDefault("filter-value")
  valid_614644 = validateParameter(valid_614644, JString, required = false,
                                 default = nil)
  if valid_614644 != nil:
    section.add "filter-value", valid_614644
  var valid_614645 = query.getOrDefault("next-token")
  valid_614645 = validateParameter(valid_614645, JString, required = false,
                                 default = nil)
  if valid_614645 != nil:
    section.add "next-token", valid_614645
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
  var valid_614646 = header.getOrDefault("X-Amz-Signature")
  valid_614646 = validateParameter(valid_614646, JString, required = false,
                                 default = nil)
  if valid_614646 != nil:
    section.add "X-Amz-Signature", valid_614646
  var valid_614647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614647 = validateParameter(valid_614647, JString, required = false,
                                 default = nil)
  if valid_614647 != nil:
    section.add "X-Amz-Content-Sha256", valid_614647
  var valid_614648 = header.getOrDefault("X-Amz-Date")
  valid_614648 = validateParameter(valid_614648, JString, required = false,
                                 default = nil)
  if valid_614648 != nil:
    section.add "X-Amz-Date", valid_614648
  var valid_614649 = header.getOrDefault("X-Amz-Credential")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "X-Amz-Credential", valid_614649
  var valid_614650 = header.getOrDefault("X-Amz-Security-Token")
  valid_614650 = validateParameter(valid_614650, JString, required = false,
                                 default = nil)
  if valid_614650 != nil:
    section.add "X-Amz-Security-Token", valid_614650
  var valid_614651 = header.getOrDefault("X-Amz-Algorithm")
  valid_614651 = validateParameter(valid_614651, JString, required = false,
                                 default = nil)
  if valid_614651 != nil:
    section.add "X-Amz-Algorithm", valid_614651
  var valid_614652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "X-Amz-SignedHeaders", valid_614652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614653: Call_ListPhoneNumbers_614635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  let valid = call_614653.validator(path, query, header, formData, body)
  let scheme = call_614653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614653.url(scheme.get, call_614653.host, call_614653.base,
                         call_614653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614653, url, valid)

proc call*(call_614654: Call_ListPhoneNumbers_614635; MaxResults: string = "";
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
  var query_614655 = newJObject()
  add(query_614655, "MaxResults", newJString(MaxResults))
  add(query_614655, "NextToken", newJString(NextToken))
  add(query_614655, "product-type", newJString(productType))
  add(query_614655, "filter-name", newJString(filterName))
  add(query_614655, "max-results", newJInt(maxResults))
  add(query_614655, "status", newJString(status))
  add(query_614655, "filter-value", newJString(filterValue))
  add(query_614655, "next-token", newJString(nextToken))
  result = call_614654.call(nil, query_614655, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_614635(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_614636, base: "/",
    url: url_ListPhoneNumbers_614637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_614656 = ref object of OpenApiRestCall_612658
proc url_ListVoiceConnectorTerminationCredentials_614658(protocol: Scheme;
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

proc validate_ListVoiceConnectorTerminationCredentials_614657(path: JsonNode;
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
  var valid_614659 = path.getOrDefault("voiceConnectorId")
  valid_614659 = validateParameter(valid_614659, JString, required = true,
                                 default = nil)
  if valid_614659 != nil:
    section.add "voiceConnectorId", valid_614659
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
  var valid_614660 = header.getOrDefault("X-Amz-Signature")
  valid_614660 = validateParameter(valid_614660, JString, required = false,
                                 default = nil)
  if valid_614660 != nil:
    section.add "X-Amz-Signature", valid_614660
  var valid_614661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614661 = validateParameter(valid_614661, JString, required = false,
                                 default = nil)
  if valid_614661 != nil:
    section.add "X-Amz-Content-Sha256", valid_614661
  var valid_614662 = header.getOrDefault("X-Amz-Date")
  valid_614662 = validateParameter(valid_614662, JString, required = false,
                                 default = nil)
  if valid_614662 != nil:
    section.add "X-Amz-Date", valid_614662
  var valid_614663 = header.getOrDefault("X-Amz-Credential")
  valid_614663 = validateParameter(valid_614663, JString, required = false,
                                 default = nil)
  if valid_614663 != nil:
    section.add "X-Amz-Credential", valid_614663
  var valid_614664 = header.getOrDefault("X-Amz-Security-Token")
  valid_614664 = validateParameter(valid_614664, JString, required = false,
                                 default = nil)
  if valid_614664 != nil:
    section.add "X-Amz-Security-Token", valid_614664
  var valid_614665 = header.getOrDefault("X-Amz-Algorithm")
  valid_614665 = validateParameter(valid_614665, JString, required = false,
                                 default = nil)
  if valid_614665 != nil:
    section.add "X-Amz-Algorithm", valid_614665
  var valid_614666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614666 = validateParameter(valid_614666, JString, required = false,
                                 default = nil)
  if valid_614666 != nil:
    section.add "X-Amz-SignedHeaders", valid_614666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614667: Call_ListVoiceConnectorTerminationCredentials_614656;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614667.validator(path, query, header, formData, body)
  let scheme = call_614667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614667.url(scheme.get, call_614667.host, call_614667.base,
                         call_614667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614667, url, valid)

proc call*(call_614668: Call_ListVoiceConnectorTerminationCredentials_614656;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_614669 = newJObject()
  add(path_614669, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_614668.call(path_614669, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_614656(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_614657,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_614658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_614670 = ref object of OpenApiRestCall_612658
proc url_LogoutUser_614672(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_LogoutUser_614671(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614673 = path.getOrDefault("userId")
  valid_614673 = validateParameter(valid_614673, JString, required = true,
                                 default = nil)
  if valid_614673 != nil:
    section.add "userId", valid_614673
  var valid_614674 = path.getOrDefault("accountId")
  valid_614674 = validateParameter(valid_614674, JString, required = true,
                                 default = nil)
  if valid_614674 != nil:
    section.add "accountId", valid_614674
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614675 = query.getOrDefault("operation")
  valid_614675 = validateParameter(valid_614675, JString, required = true,
                                 default = newJString("logout"))
  if valid_614675 != nil:
    section.add "operation", valid_614675
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
  var valid_614676 = header.getOrDefault("X-Amz-Signature")
  valid_614676 = validateParameter(valid_614676, JString, required = false,
                                 default = nil)
  if valid_614676 != nil:
    section.add "X-Amz-Signature", valid_614676
  var valid_614677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614677 = validateParameter(valid_614677, JString, required = false,
                                 default = nil)
  if valid_614677 != nil:
    section.add "X-Amz-Content-Sha256", valid_614677
  var valid_614678 = header.getOrDefault("X-Amz-Date")
  valid_614678 = validateParameter(valid_614678, JString, required = false,
                                 default = nil)
  if valid_614678 != nil:
    section.add "X-Amz-Date", valid_614678
  var valid_614679 = header.getOrDefault("X-Amz-Credential")
  valid_614679 = validateParameter(valid_614679, JString, required = false,
                                 default = nil)
  if valid_614679 != nil:
    section.add "X-Amz-Credential", valid_614679
  var valid_614680 = header.getOrDefault("X-Amz-Security-Token")
  valid_614680 = validateParameter(valid_614680, JString, required = false,
                                 default = nil)
  if valid_614680 != nil:
    section.add "X-Amz-Security-Token", valid_614680
  var valid_614681 = header.getOrDefault("X-Amz-Algorithm")
  valid_614681 = validateParameter(valid_614681, JString, required = false,
                                 default = nil)
  if valid_614681 != nil:
    section.add "X-Amz-Algorithm", valid_614681
  var valid_614682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614682 = validateParameter(valid_614682, JString, required = false,
                                 default = nil)
  if valid_614682 != nil:
    section.add "X-Amz-SignedHeaders", valid_614682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614683: Call_LogoutUser_614670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_614683.validator(path, query, header, formData, body)
  let scheme = call_614683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614683.url(scheme.get, call_614683.host, call_614683.base,
                         call_614683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614683, url, valid)

proc call*(call_614684: Call_LogoutUser_614670; userId: string; accountId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614685 = newJObject()
  var query_614686 = newJObject()
  add(query_614686, "operation", newJString(operation))
  add(path_614685, "userId", newJString(userId))
  add(path_614685, "accountId", newJString(accountId))
  result = call_614684.call(path_614685, query_614686, nil, nil, nil)

var logoutUser* = Call_LogoutUser_614670(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_614671,
                                      base: "/", url: url_LogoutUser_614672,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_614687 = ref object of OpenApiRestCall_612658
proc url_PutVoiceConnectorTerminationCredentials_614689(protocol: Scheme;
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

proc validate_PutVoiceConnectorTerminationCredentials_614688(path: JsonNode;
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
  var valid_614690 = path.getOrDefault("voiceConnectorId")
  valid_614690 = validateParameter(valid_614690, JString, required = true,
                                 default = nil)
  if valid_614690 != nil:
    section.add "voiceConnectorId", valid_614690
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614691 = query.getOrDefault("operation")
  valid_614691 = validateParameter(valid_614691, JString, required = true,
                                 default = newJString("put"))
  if valid_614691 != nil:
    section.add "operation", valid_614691
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
  var valid_614692 = header.getOrDefault("X-Amz-Signature")
  valid_614692 = validateParameter(valid_614692, JString, required = false,
                                 default = nil)
  if valid_614692 != nil:
    section.add "X-Amz-Signature", valid_614692
  var valid_614693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614693 = validateParameter(valid_614693, JString, required = false,
                                 default = nil)
  if valid_614693 != nil:
    section.add "X-Amz-Content-Sha256", valid_614693
  var valid_614694 = header.getOrDefault("X-Amz-Date")
  valid_614694 = validateParameter(valid_614694, JString, required = false,
                                 default = nil)
  if valid_614694 != nil:
    section.add "X-Amz-Date", valid_614694
  var valid_614695 = header.getOrDefault("X-Amz-Credential")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "X-Amz-Credential", valid_614695
  var valid_614696 = header.getOrDefault("X-Amz-Security-Token")
  valid_614696 = validateParameter(valid_614696, JString, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "X-Amz-Security-Token", valid_614696
  var valid_614697 = header.getOrDefault("X-Amz-Algorithm")
  valid_614697 = validateParameter(valid_614697, JString, required = false,
                                 default = nil)
  if valid_614697 != nil:
    section.add "X-Amz-Algorithm", valid_614697
  var valid_614698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614698 = validateParameter(valid_614698, JString, required = false,
                                 default = nil)
  if valid_614698 != nil:
    section.add "X-Amz-SignedHeaders", valid_614698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614700: Call_PutVoiceConnectorTerminationCredentials_614687;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_614700.validator(path, query, header, formData, body)
  let scheme = call_614700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614700.url(scheme.get, call_614700.host, call_614700.base,
                         call_614700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614700, url, valid)

proc call*(call_614701: Call_PutVoiceConnectorTerminationCredentials_614687;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_614702 = newJObject()
  var query_614703 = newJObject()
  var body_614704 = newJObject()
  add(query_614703, "operation", newJString(operation))
  add(path_614702, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_614704 = body
  result = call_614701.call(path_614702, query_614703, nil, nil, body_614704)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_614687(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_614688, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_614689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_614705 = ref object of OpenApiRestCall_612658
proc url_RegenerateSecurityToken_614707(protocol: Scheme; host: string; base: string;
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

proc validate_RegenerateSecurityToken_614706(path: JsonNode; query: JsonNode;
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
  var valid_614708 = path.getOrDefault("botId")
  valid_614708 = validateParameter(valid_614708, JString, required = true,
                                 default = nil)
  if valid_614708 != nil:
    section.add "botId", valid_614708
  var valid_614709 = path.getOrDefault("accountId")
  valid_614709 = validateParameter(valid_614709, JString, required = true,
                                 default = nil)
  if valid_614709 != nil:
    section.add "accountId", valid_614709
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614710 = query.getOrDefault("operation")
  valid_614710 = validateParameter(valid_614710, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_614710 != nil:
    section.add "operation", valid_614710
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
  var valid_614711 = header.getOrDefault("X-Amz-Signature")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "X-Amz-Signature", valid_614711
  var valid_614712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614712 = validateParameter(valid_614712, JString, required = false,
                                 default = nil)
  if valid_614712 != nil:
    section.add "X-Amz-Content-Sha256", valid_614712
  var valid_614713 = header.getOrDefault("X-Amz-Date")
  valid_614713 = validateParameter(valid_614713, JString, required = false,
                                 default = nil)
  if valid_614713 != nil:
    section.add "X-Amz-Date", valid_614713
  var valid_614714 = header.getOrDefault("X-Amz-Credential")
  valid_614714 = validateParameter(valid_614714, JString, required = false,
                                 default = nil)
  if valid_614714 != nil:
    section.add "X-Amz-Credential", valid_614714
  var valid_614715 = header.getOrDefault("X-Amz-Security-Token")
  valid_614715 = validateParameter(valid_614715, JString, required = false,
                                 default = nil)
  if valid_614715 != nil:
    section.add "X-Amz-Security-Token", valid_614715
  var valid_614716 = header.getOrDefault("X-Amz-Algorithm")
  valid_614716 = validateParameter(valid_614716, JString, required = false,
                                 default = nil)
  if valid_614716 != nil:
    section.add "X-Amz-Algorithm", valid_614716
  var valid_614717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614717 = validateParameter(valid_614717, JString, required = false,
                                 default = nil)
  if valid_614717 != nil:
    section.add "X-Amz-SignedHeaders", valid_614717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614718: Call_RegenerateSecurityToken_614705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_614718.validator(path, query, header, formData, body)
  let scheme = call_614718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614718.url(scheme.get, call_614718.host, call_614718.base,
                         call_614718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614718, url, valid)

proc call*(call_614719: Call_RegenerateSecurityToken_614705; botId: string;
          accountId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614720 = newJObject()
  var query_614721 = newJObject()
  add(path_614720, "botId", newJString(botId))
  add(query_614721, "operation", newJString(operation))
  add(path_614720, "accountId", newJString(accountId))
  result = call_614719.call(path_614720, query_614721, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_614705(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_614706, base: "/",
    url: url_RegenerateSecurityToken_614707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_614722 = ref object of OpenApiRestCall_612658
proc url_ResetPersonalPIN_614724(protocol: Scheme; host: string; base: string;
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

proc validate_ResetPersonalPIN_614723(path: JsonNode; query: JsonNode;
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
  var valid_614725 = path.getOrDefault("userId")
  valid_614725 = validateParameter(valid_614725, JString, required = true,
                                 default = nil)
  if valid_614725 != nil:
    section.add "userId", valid_614725
  var valid_614726 = path.getOrDefault("accountId")
  valid_614726 = validateParameter(valid_614726, JString, required = true,
                                 default = nil)
  if valid_614726 != nil:
    section.add "accountId", valid_614726
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614727 = query.getOrDefault("operation")
  valid_614727 = validateParameter(valid_614727, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_614727 != nil:
    section.add "operation", valid_614727
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
  var valid_614728 = header.getOrDefault("X-Amz-Signature")
  valid_614728 = validateParameter(valid_614728, JString, required = false,
                                 default = nil)
  if valid_614728 != nil:
    section.add "X-Amz-Signature", valid_614728
  var valid_614729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614729 = validateParameter(valid_614729, JString, required = false,
                                 default = nil)
  if valid_614729 != nil:
    section.add "X-Amz-Content-Sha256", valid_614729
  var valid_614730 = header.getOrDefault("X-Amz-Date")
  valid_614730 = validateParameter(valid_614730, JString, required = false,
                                 default = nil)
  if valid_614730 != nil:
    section.add "X-Amz-Date", valid_614730
  var valid_614731 = header.getOrDefault("X-Amz-Credential")
  valid_614731 = validateParameter(valid_614731, JString, required = false,
                                 default = nil)
  if valid_614731 != nil:
    section.add "X-Amz-Credential", valid_614731
  var valid_614732 = header.getOrDefault("X-Amz-Security-Token")
  valid_614732 = validateParameter(valid_614732, JString, required = false,
                                 default = nil)
  if valid_614732 != nil:
    section.add "X-Amz-Security-Token", valid_614732
  var valid_614733 = header.getOrDefault("X-Amz-Algorithm")
  valid_614733 = validateParameter(valid_614733, JString, required = false,
                                 default = nil)
  if valid_614733 != nil:
    section.add "X-Amz-Algorithm", valid_614733
  var valid_614734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614734 = validateParameter(valid_614734, JString, required = false,
                                 default = nil)
  if valid_614734 != nil:
    section.add "X-Amz-SignedHeaders", valid_614734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614735: Call_ResetPersonalPIN_614722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_614735.validator(path, query, header, formData, body)
  let scheme = call_614735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614735.url(scheme.get, call_614735.host, call_614735.base,
                         call_614735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614735, url, valid)

proc call*(call_614736: Call_ResetPersonalPIN_614722; userId: string;
          accountId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_614737 = newJObject()
  var query_614738 = newJObject()
  add(query_614738, "operation", newJString(operation))
  add(path_614737, "userId", newJString(userId))
  add(path_614737, "accountId", newJString(accountId))
  result = call_614736.call(path_614737, query_614738, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_614722(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_614723, base: "/",
    url: url_ResetPersonalPIN_614724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_614739 = ref object of OpenApiRestCall_612658
proc url_RestorePhoneNumber_614741(protocol: Scheme; host: string; base: string;
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

proc validate_RestorePhoneNumber_614740(path: JsonNode; query: JsonNode;
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
  var valid_614742 = path.getOrDefault("phoneNumberId")
  valid_614742 = validateParameter(valid_614742, JString, required = true,
                                 default = nil)
  if valid_614742 != nil:
    section.add "phoneNumberId", valid_614742
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_614743 = query.getOrDefault("operation")
  valid_614743 = validateParameter(valid_614743, JString, required = true,
                                 default = newJString("restore"))
  if valid_614743 != nil:
    section.add "operation", valid_614743
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
  var valid_614744 = header.getOrDefault("X-Amz-Signature")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "X-Amz-Signature", valid_614744
  var valid_614745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "X-Amz-Content-Sha256", valid_614745
  var valid_614746 = header.getOrDefault("X-Amz-Date")
  valid_614746 = validateParameter(valid_614746, JString, required = false,
                                 default = nil)
  if valid_614746 != nil:
    section.add "X-Amz-Date", valid_614746
  var valid_614747 = header.getOrDefault("X-Amz-Credential")
  valid_614747 = validateParameter(valid_614747, JString, required = false,
                                 default = nil)
  if valid_614747 != nil:
    section.add "X-Amz-Credential", valid_614747
  var valid_614748 = header.getOrDefault("X-Amz-Security-Token")
  valid_614748 = validateParameter(valid_614748, JString, required = false,
                                 default = nil)
  if valid_614748 != nil:
    section.add "X-Amz-Security-Token", valid_614748
  var valid_614749 = header.getOrDefault("X-Amz-Algorithm")
  valid_614749 = validateParameter(valid_614749, JString, required = false,
                                 default = nil)
  if valid_614749 != nil:
    section.add "X-Amz-Algorithm", valid_614749
  var valid_614750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614750 = validateParameter(valid_614750, JString, required = false,
                                 default = nil)
  if valid_614750 != nil:
    section.add "X-Amz-SignedHeaders", valid_614750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614751: Call_RestorePhoneNumber_614739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_614751.validator(path, query, header, formData, body)
  let scheme = call_614751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614751.url(scheme.get, call_614751.host, call_614751.base,
                         call_614751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614751, url, valid)

proc call*(call_614752: Call_RestorePhoneNumber_614739; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_614753 = newJObject()
  var query_614754 = newJObject()
  add(path_614753, "phoneNumberId", newJString(phoneNumberId))
  add(query_614754, "operation", newJString(operation))
  result = call_614752.call(path_614753, query_614754, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_614739(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_614740, base: "/",
    url: url_RestorePhoneNumber_614741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_614755 = ref object of OpenApiRestCall_612658
proc url_SearchAvailablePhoneNumbers_614757(protocol: Scheme; host: string;
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

proc validate_SearchAvailablePhoneNumbers_614756(path: JsonNode; query: JsonNode;
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
  var valid_614758 = query.getOrDefault("state")
  valid_614758 = validateParameter(valid_614758, JString, required = false,
                                 default = nil)
  if valid_614758 != nil:
    section.add "state", valid_614758
  var valid_614759 = query.getOrDefault("area-code")
  valid_614759 = validateParameter(valid_614759, JString, required = false,
                                 default = nil)
  if valid_614759 != nil:
    section.add "area-code", valid_614759
  var valid_614760 = query.getOrDefault("toll-free-prefix")
  valid_614760 = validateParameter(valid_614760, JString, required = false,
                                 default = nil)
  if valid_614760 != nil:
    section.add "toll-free-prefix", valid_614760
  var valid_614761 = query.getOrDefault("type")
  valid_614761 = validateParameter(valid_614761, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_614761 != nil:
    section.add "type", valid_614761
  var valid_614762 = query.getOrDefault("city")
  valid_614762 = validateParameter(valid_614762, JString, required = false,
                                 default = nil)
  if valid_614762 != nil:
    section.add "city", valid_614762
  var valid_614763 = query.getOrDefault("country")
  valid_614763 = validateParameter(valid_614763, JString, required = false,
                                 default = nil)
  if valid_614763 != nil:
    section.add "country", valid_614763
  var valid_614764 = query.getOrDefault("max-results")
  valid_614764 = validateParameter(valid_614764, JInt, required = false, default = nil)
  if valid_614764 != nil:
    section.add "max-results", valid_614764
  var valid_614765 = query.getOrDefault("next-token")
  valid_614765 = validateParameter(valid_614765, JString, required = false,
                                 default = nil)
  if valid_614765 != nil:
    section.add "next-token", valid_614765
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
  var valid_614766 = header.getOrDefault("X-Amz-Signature")
  valid_614766 = validateParameter(valid_614766, JString, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "X-Amz-Signature", valid_614766
  var valid_614767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614767 = validateParameter(valid_614767, JString, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "X-Amz-Content-Sha256", valid_614767
  var valid_614768 = header.getOrDefault("X-Amz-Date")
  valid_614768 = validateParameter(valid_614768, JString, required = false,
                                 default = nil)
  if valid_614768 != nil:
    section.add "X-Amz-Date", valid_614768
  var valid_614769 = header.getOrDefault("X-Amz-Credential")
  valid_614769 = validateParameter(valid_614769, JString, required = false,
                                 default = nil)
  if valid_614769 != nil:
    section.add "X-Amz-Credential", valid_614769
  var valid_614770 = header.getOrDefault("X-Amz-Security-Token")
  valid_614770 = validateParameter(valid_614770, JString, required = false,
                                 default = nil)
  if valid_614770 != nil:
    section.add "X-Amz-Security-Token", valid_614770
  var valid_614771 = header.getOrDefault("X-Amz-Algorithm")
  valid_614771 = validateParameter(valid_614771, JString, required = false,
                                 default = nil)
  if valid_614771 != nil:
    section.add "X-Amz-Algorithm", valid_614771
  var valid_614772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "X-Amz-SignedHeaders", valid_614772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614773: Call_SearchAvailablePhoneNumbers_614755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_614773.validator(path, query, header, formData, body)
  let scheme = call_614773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614773.url(scheme.get, call_614773.host, call_614773.base,
                         call_614773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614773, url, valid)

proc call*(call_614774: Call_SearchAvailablePhoneNumbers_614755;
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
  var query_614775 = newJObject()
  add(query_614775, "state", newJString(state))
  add(query_614775, "area-code", newJString(areaCode))
  add(query_614775, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_614775, "type", newJString(`type`))
  add(query_614775, "city", newJString(city))
  add(query_614775, "country", newJString(country))
  add(query_614775, "max-results", newJInt(maxResults))
  add(query_614775, "next-token", newJString(nextToken))
  result = call_614774.call(nil, query_614775, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_614755(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_614756, base: "/",
    url: url_SearchAvailablePhoneNumbers_614757,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
