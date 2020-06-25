
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociatePhoneNumberWithUser_21625779 = ref object of OpenApiRestCall_21625435
proc url_AssociatePhoneNumberWithUser_21625781(protocol: Scheme; host: string;
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

proc validate_AssociatePhoneNumberWithUser_21625780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21625895 = path.getOrDefault("accountId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "accountId", valid_21625895
  var valid_21625896 = path.getOrDefault("userId")
  valid_21625896 = validateParameter(valid_21625896, JString, required = true,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "userId", valid_21625896
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21625911 = query.getOrDefault("operation")
  valid_21625911 = validateParameter(valid_21625911, JString, required = true, default = newJString(
      "associate-phone-number"))
  if valid_21625911 != nil:
    section.add "operation", valid_21625911
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
  var valid_21625912 = header.getOrDefault("X-Amz-Date")
  valid_21625912 = validateParameter(valid_21625912, JString, required = false,
                                   default = nil)
  if valid_21625912 != nil:
    section.add "X-Amz-Date", valid_21625912
  var valid_21625913 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625913 = validateParameter(valid_21625913, JString, required = false,
                                   default = nil)
  if valid_21625913 != nil:
    section.add "X-Amz-Security-Token", valid_21625913
  var valid_21625914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625914 = validateParameter(valid_21625914, JString, required = false,
                                   default = nil)
  if valid_21625914 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625914
  var valid_21625915 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625915 = validateParameter(valid_21625915, JString, required = false,
                                   default = nil)
  if valid_21625915 != nil:
    section.add "X-Amz-Algorithm", valid_21625915
  var valid_21625916 = header.getOrDefault("X-Amz-Signature")
  valid_21625916 = validateParameter(valid_21625916, JString, required = false,
                                   default = nil)
  if valid_21625916 != nil:
    section.add "X-Amz-Signature", valid_21625916
  var valid_21625917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625917 = validateParameter(valid_21625917, JString, required = false,
                                   default = nil)
  if valid_21625917 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625917
  var valid_21625918 = header.getOrDefault("X-Amz-Credential")
  valid_21625918 = validateParameter(valid_21625918, JString, required = false,
                                   default = nil)
  if valid_21625918 != nil:
    section.add "X-Amz-Credential", valid_21625918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625944: Call_AssociatePhoneNumberWithUser_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_21625944.validator(path, query, header, formData, body, _)
  let scheme = call_21625944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625944.makeUrl(scheme.get, call_21625944.host, call_21625944.base,
                               call_21625944.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625944, uri, valid, _)

proc call*(call_21626007: Call_AssociatePhoneNumberWithUser_21625779;
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
  var path_21626009 = newJObject()
  var query_21626011 = newJObject()
  var body_21626012 = newJObject()
  add(path_21626009, "accountId", newJString(accountId))
  add(query_21626011, "operation", newJString(operation))
  if body != nil:
    body_21626012 = body
  add(path_21626009, "userId", newJString(userId))
  result = call_21626007.call(path_21626009, query_21626011, nil, nil, body_21626012)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_21625779(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_21625780, base: "/",
    makeUrl: url_AssociatePhoneNumberWithUser_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_21626050 = ref object of OpenApiRestCall_21625435
proc url_AssociatePhoneNumbersWithVoiceConnector_21626052(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnector_21626051(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626053 = path.getOrDefault("voiceConnectorId")
  valid_21626053 = validateParameter(valid_21626053, JString, required = true,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "voiceConnectorId", valid_21626053
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626054 = query.getOrDefault("operation")
  valid_21626054 = validateParameter(valid_21626054, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_21626054 != nil:
    section.add "operation", valid_21626054
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
  var valid_21626055 = header.getOrDefault("X-Amz-Date")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Date", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Security-Token", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Algorithm", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Signature")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Signature", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Credential")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Credential", valid_21626061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626063: Call_AssociatePhoneNumbersWithVoiceConnector_21626050;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21626063.validator(path, query, header, formData, body, _)
  let scheme = call_21626063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626063.makeUrl(scheme.get, call_21626063.host, call_21626063.base,
                               call_21626063.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626063, uri, valid, _)

proc call*(call_21626064: Call_AssociatePhoneNumbersWithVoiceConnector_21626050;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21626065 = newJObject()
  var query_21626066 = newJObject()
  var body_21626067 = newJObject()
  add(path_21626065, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_21626066, "operation", newJString(operation))
  if body != nil:
    body_21626067 = body
  result = call_21626064.call(path_21626065, query_21626066, nil, nil, body_21626067)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_21626050(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_21626051,
    base: "/", makeUrl: url_AssociatePhoneNumbersWithVoiceConnector_21626052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnectorGroup_21626068 = ref object of OpenApiRestCall_21625435
proc url_AssociatePhoneNumbersWithVoiceConnectorGroup_21626070(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnectorGroup_21626069(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_21626071 = path.getOrDefault("voiceConnectorGroupId")
  valid_21626071 = validateParameter(valid_21626071, JString, required = true,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "voiceConnectorGroupId", valid_21626071
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626072 = query.getOrDefault("operation")
  valid_21626072 = validateParameter(valid_21626072, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_21626072 != nil:
    section.add "operation", valid_21626072
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
  var valid_21626073 = header.getOrDefault("X-Amz-Date")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Date", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Security-Token", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Algorithm", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Signature")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Signature", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Credential")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Credential", valid_21626079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626081: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_21626068;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_21626081.validator(path, query, header, formData, body, _)
  let scheme = call_21626081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626081.makeUrl(scheme.get, call_21626081.host, call_21626081.base,
                               call_21626081.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626081, uri, valid, _)

proc call*(call_21626082: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_21626068;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnectorGroup
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21626083 = newJObject()
  var query_21626084 = newJObject()
  var body_21626085 = newJObject()
  add(path_21626083, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_21626084, "operation", newJString(operation))
  if body != nil:
    body_21626085 = body
  result = call_21626082.call(path_21626083, query_21626084, nil, nil, body_21626085)

var associatePhoneNumbersWithVoiceConnectorGroup* = Call_AssociatePhoneNumbersWithVoiceConnectorGroup_21626068(
    name: "associatePhoneNumbersWithVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnectorGroup_21626069,
    base: "/", makeUrl: url_AssociatePhoneNumbersWithVoiceConnectorGroup_21626070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSigninDelegateGroupsWithAccount_21626086 = ref object of OpenApiRestCall_21625435
proc url_AssociateSigninDelegateGroupsWithAccount_21626088(protocol: Scheme;
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

proc validate_AssociateSigninDelegateGroupsWithAccount_21626087(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626089 = path.getOrDefault("accountId")
  valid_21626089 = validateParameter(valid_21626089, JString, required = true,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "accountId", valid_21626089
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626090 = query.getOrDefault("operation")
  valid_21626090 = validateParameter(valid_21626090, JString, required = true, default = newJString(
      "associate-signin-delegate-groups"))
  if valid_21626090 != nil:
    section.add "operation", valid_21626090
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
  var valid_21626091 = header.getOrDefault("X-Amz-Date")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Date", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Security-Token", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Algorithm", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Signature")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Signature", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Credential")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Credential", valid_21626097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626099: Call_AssociateSigninDelegateGroupsWithAccount_21626086;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ## 
  let valid = call_21626099.validator(path, query, header, formData, body, _)
  let scheme = call_21626099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626099.makeUrl(scheme.get, call_21626099.host, call_21626099.base,
                               call_21626099.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626099, uri, valid, _)

proc call*(call_21626100: Call_AssociateSigninDelegateGroupsWithAccount_21626086;
          accountId: string; body: JsonNode;
          operation: string = "associate-signin-delegate-groups"): Recallable =
  ## associateSigninDelegateGroupsWithAccount
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21626101 = newJObject()
  var query_21626102 = newJObject()
  var body_21626103 = newJObject()
  add(path_21626101, "accountId", newJString(accountId))
  add(query_21626102, "operation", newJString(operation))
  if body != nil:
    body_21626103 = body
  result = call_21626100.call(path_21626101, query_21626102, nil, nil, body_21626103)

var associateSigninDelegateGroupsWithAccount* = Call_AssociateSigninDelegateGroupsWithAccount_21626086(
    name: "associateSigninDelegateGroupsWithAccount", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}#operation=associate-signin-delegate-groups",
    validator: validate_AssociateSigninDelegateGroupsWithAccount_21626087,
    base: "/", makeUrl: url_AssociateSigninDelegateGroupsWithAccount_21626088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateAttendee_21626104 = ref object of OpenApiRestCall_21625435
proc url_BatchCreateAttendee_21626106(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreateAttendee_21626105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_21626107 = path.getOrDefault("meetingId")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "meetingId", valid_21626107
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626108 = query.getOrDefault("operation")
  valid_21626108 = validateParameter(valid_21626108, JString, required = true,
                                   default = newJString("batch-create"))
  if valid_21626108 != nil:
    section.add "operation", valid_21626108
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
  var valid_21626109 = header.getOrDefault("X-Amz-Date")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Date", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Security-Token", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Algorithm", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Signature")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Signature", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Credential")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Credential", valid_21626115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626117: Call_BatchCreateAttendee_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  let valid = call_21626117.validator(path, query, header, formData, body, _)
  let scheme = call_21626117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626117.makeUrl(scheme.get, call_21626117.host, call_21626117.base,
                               call_21626117.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626117, uri, valid, _)

proc call*(call_21626118: Call_BatchCreateAttendee_21626104; body: JsonNode;
          meetingId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateAttendee
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_21626119 = newJObject()
  var query_21626120 = newJObject()
  var body_21626121 = newJObject()
  add(query_21626120, "operation", newJString(operation))
  if body != nil:
    body_21626121 = body
  add(path_21626119, "meetingId", newJString(meetingId))
  result = call_21626118.call(path_21626119, query_21626120, nil, nil, body_21626121)

var batchCreateAttendee* = Call_BatchCreateAttendee_21626104(
    name: "batchCreateAttendee", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees#operation=batch-create",
    validator: validate_BatchCreateAttendee_21626105, base: "/",
    makeUrl: url_BatchCreateAttendee_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateRoomMembership_21626122 = ref object of OpenApiRestCall_21625435
proc url_BatchCreateRoomMembership_21626124(protocol: Scheme; host: string;
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

proc validate_BatchCreateRoomMembership_21626123(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626125 = path.getOrDefault("accountId")
  valid_21626125 = validateParameter(valid_21626125, JString, required = true,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "accountId", valid_21626125
  var valid_21626126 = path.getOrDefault("roomId")
  valid_21626126 = validateParameter(valid_21626126, JString, required = true,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "roomId", valid_21626126
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626127 = query.getOrDefault("operation")
  valid_21626127 = validateParameter(valid_21626127, JString, required = true,
                                   default = newJString("batch-create"))
  if valid_21626127 != nil:
    section.add "operation", valid_21626127
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
  var valid_21626128 = header.getOrDefault("X-Amz-Date")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Date", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Security-Token", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Algorithm", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Signature")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Signature", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Credential")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Credential", valid_21626134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626136: Call_BatchCreateRoomMembership_21626122;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds up to 50 members to a chat room in an Amazon Chime Enterprise account. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_21626136.validator(path, query, header, formData, body, _)
  let scheme = call_21626136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626136.makeUrl(scheme.get, call_21626136.host, call_21626136.base,
                               call_21626136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626136, uri, valid, _)

proc call*(call_21626137: Call_BatchCreateRoomMembership_21626122;
          accountId: string; body: JsonNode; roomId: string;
          operation: string = "batch-create"): Recallable =
  ## batchCreateRoomMembership
  ## Adds up to 50 members to a chat room in an Amazon Chime Enterprise account. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_21626138 = newJObject()
  var query_21626139 = newJObject()
  var body_21626140 = newJObject()
  add(path_21626138, "accountId", newJString(accountId))
  add(query_21626139, "operation", newJString(operation))
  if body != nil:
    body_21626140 = body
  add(path_21626138, "roomId", newJString(roomId))
  result = call_21626137.call(path_21626138, query_21626139, nil, nil, body_21626140)

var batchCreateRoomMembership* = Call_BatchCreateRoomMembership_21626122(
    name: "batchCreateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}/memberships#operation=batch-create",
    validator: validate_BatchCreateRoomMembership_21626123, base: "/",
    makeUrl: url_BatchCreateRoomMembership_21626124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_21626141 = ref object of OpenApiRestCall_21625435
proc url_BatchDeletePhoneNumber_21626143(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeletePhoneNumber_21626142(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626144 = query.getOrDefault("operation")
  valid_21626144 = validateParameter(valid_21626144, JString, required = true,
                                   default = newJString("batch-delete"))
  if valid_21626144 != nil:
    section.add "operation", valid_21626144
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
  var valid_21626145 = header.getOrDefault("X-Amz-Date")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Date", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Security-Token", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Algorithm", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Signature")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Signature", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Credential")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Credential", valid_21626151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626153: Call_BatchDeletePhoneNumber_21626141;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_21626153.validator(path, query, header, formData, body, _)
  let scheme = call_21626153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626153.makeUrl(scheme.get, call_21626153.host, call_21626153.base,
                               call_21626153.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626153, uri, valid, _)

proc call*(call_21626154: Call_BatchDeletePhoneNumber_21626141; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_21626155 = newJObject()
  var body_21626156 = newJObject()
  add(query_21626155, "operation", newJString(operation))
  if body != nil:
    body_21626156 = body
  result = call_21626154.call(nil, query_21626155, nil, nil, body_21626156)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_21626141(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_21626142, base: "/",
    makeUrl: url_BatchDeletePhoneNumber_21626143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_21626157 = ref object of OpenApiRestCall_21625435
proc url_BatchSuspendUser_21626159(protocol: Scheme; host: string; base: string;
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

proc validate_BatchSuspendUser_21626158(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626160 = path.getOrDefault("accountId")
  valid_21626160 = validateParameter(valid_21626160, JString, required = true,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "accountId", valid_21626160
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626161 = query.getOrDefault("operation")
  valid_21626161 = validateParameter(valid_21626161, JString, required = true,
                                   default = newJString("suspend"))
  if valid_21626161 != nil:
    section.add "operation", valid_21626161
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
  var valid_21626162 = header.getOrDefault("X-Amz-Date")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Date", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Security-Token", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Algorithm", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Signature")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Signature", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Credential")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Credential", valid_21626168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626170: Call_BatchSuspendUser_21626157; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_21626170.validator(path, query, header, formData, body, _)
  let scheme = call_21626170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626170.makeUrl(scheme.get, call_21626170.host, call_21626170.base,
                               call_21626170.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626170, uri, valid, _)

proc call*(call_21626171: Call_BatchSuspendUser_21626157; accountId: string;
          body: JsonNode; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21626172 = newJObject()
  var query_21626173 = newJObject()
  var body_21626174 = newJObject()
  add(path_21626172, "accountId", newJString(accountId))
  add(query_21626173, "operation", newJString(operation))
  if body != nil:
    body_21626174 = body
  result = call_21626171.call(path_21626172, query_21626173, nil, nil, body_21626174)

var batchSuspendUser* = Call_BatchSuspendUser_21626157(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_21626158, base: "/",
    makeUrl: url_BatchSuspendUser_21626159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_21626175 = ref object of OpenApiRestCall_21625435
proc url_BatchUnsuspendUser_21626177(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUnsuspendUser_21626176(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626178 = path.getOrDefault("accountId")
  valid_21626178 = validateParameter(valid_21626178, JString, required = true,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "accountId", valid_21626178
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626179 = query.getOrDefault("operation")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = newJString("unsuspend"))
  if valid_21626179 != nil:
    section.add "operation", valid_21626179
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
  var valid_21626180 = header.getOrDefault("X-Amz-Date")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Date", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Security-Token", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Algorithm", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Signature")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Signature", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Credential")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Credential", valid_21626186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626188: Call_BatchUnsuspendUser_21626175; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_21626188.validator(path, query, header, formData, body, _)
  let scheme = call_21626188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626188.makeUrl(scheme.get, call_21626188.host, call_21626188.base,
                               call_21626188.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626188, uri, valid, _)

proc call*(call_21626189: Call_BatchUnsuspendUser_21626175; accountId: string;
          body: JsonNode; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21626190 = newJObject()
  var query_21626191 = newJObject()
  var body_21626192 = newJObject()
  add(path_21626190, "accountId", newJString(accountId))
  add(query_21626191, "operation", newJString(operation))
  if body != nil:
    body_21626192 = body
  result = call_21626189.call(path_21626190, query_21626191, nil, nil, body_21626192)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_21626175(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_21626176, base: "/",
    makeUrl: url_BatchUnsuspendUser_21626177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_21626193 = ref object of OpenApiRestCall_21625435
proc url_BatchUpdatePhoneNumber_21626195(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchUpdatePhoneNumber_21626194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626196 = query.getOrDefault("operation")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = newJString("batch-update"))
  if valid_21626196 != nil:
    section.add "operation", valid_21626196
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Algorithm", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Signature")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Signature", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Credential")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Credential", valid_21626203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626205: Call_BatchUpdatePhoneNumber_21626193;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_BatchUpdatePhoneNumber_21626193; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_21626207 = newJObject()
  var body_21626208 = newJObject()
  add(query_21626207, "operation", newJString(operation))
  if body != nil:
    body_21626208 = body
  result = call_21626206.call(nil, query_21626207, nil, nil, body_21626208)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_21626193(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_21626194, base: "/",
    makeUrl: url_BatchUpdatePhoneNumber_21626195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_21626231 = ref object of OpenApiRestCall_21625435
proc url_BatchUpdateUser_21626233(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateUser_21626232(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626234 = path.getOrDefault("accountId")
  valid_21626234 = validateParameter(valid_21626234, JString, required = true,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "accountId", valid_21626234
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
  var valid_21626235 = header.getOrDefault("X-Amz-Date")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Date", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Security-Token", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Algorithm", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Signature")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Signature", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Credential")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Credential", valid_21626241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626243: Call_BatchUpdateUser_21626231; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_21626243.validator(path, query, header, formData, body, _)
  let scheme = call_21626243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626243.makeUrl(scheme.get, call_21626243.host, call_21626243.base,
                               call_21626243.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626243, uri, valid, _)

proc call*(call_21626244: Call_BatchUpdateUser_21626231; accountId: string;
          body: JsonNode): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_21626245 = newJObject()
  var body_21626246 = newJObject()
  add(path_21626245, "accountId", newJString(accountId))
  if body != nil:
    body_21626246 = body
  result = call_21626244.call(path_21626245, nil, nil, nil, body_21626246)

var batchUpdateUser* = Call_BatchUpdateUser_21626231(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_21626232,
    base: "/", makeUrl: url_BatchUpdateUser_21626233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_21626209 = ref object of OpenApiRestCall_21625435
proc url_ListUsers_21626211(protocol: Scheme; host: string; base: string;
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

proc validate_ListUsers_21626210(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626212 = path.getOrDefault("accountId")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "accountId", valid_21626212
  result.add "path", section
  ## parameters in `query` object:
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
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626213 = query.getOrDefault("user-email")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "user-email", valid_21626213
  var valid_21626214 = query.getOrDefault("NextToken")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "NextToken", valid_21626214
  var valid_21626215 = query.getOrDefault("user-type")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = newJString("PrivateUser"))
  if valid_21626215 != nil:
    section.add "user-type", valid_21626215
  var valid_21626216 = query.getOrDefault("max-results")
  valid_21626216 = validateParameter(valid_21626216, JInt, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "max-results", valid_21626216
  var valid_21626217 = query.getOrDefault("next-token")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "next-token", valid_21626217
  var valid_21626218 = query.getOrDefault("MaxResults")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "MaxResults", valid_21626218
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
  var valid_21626219 = header.getOrDefault("X-Amz-Date")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Date", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Security-Token", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Algorithm", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Signature")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Signature", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Credential")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Credential", valid_21626225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626226: Call_ListUsers_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_21626226.validator(path, query, header, formData, body, _)
  let scheme = call_21626226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626226.makeUrl(scheme.get, call_21626226.host, call_21626226.base,
                               call_21626226.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626226, uri, valid, _)

proc call*(call_21626227: Call_ListUsers_21626209; accountId: string;
          userEmail: string = ""; NextToken: string = "";
          userType: string = "PrivateUser"; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listUsers
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userEmail: string
  ##            : Optional. The user email address used to filter results. Maximum 1.
  ##   NextToken: string
  ##            : Pagination token
  ##   userType: string
  ##           : The user type.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Defaults to 100.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626228 = newJObject()
  var query_21626229 = newJObject()
  add(path_21626228, "accountId", newJString(accountId))
  add(query_21626229, "user-email", newJString(userEmail))
  add(query_21626229, "NextToken", newJString(NextToken))
  add(query_21626229, "user-type", newJString(userType))
  add(query_21626229, "max-results", newJInt(maxResults))
  add(query_21626229, "next-token", newJString(nextToken))
  add(query_21626229, "MaxResults", newJString(MaxResults))
  result = call_21626227.call(path_21626228, query_21626229, nil, nil, nil)

var listUsers* = Call_ListUsers_21626209(name: "listUsers", meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/users",
                                      validator: validate_ListUsers_21626210,
                                      base: "/", makeUrl: url_ListUsers_21626211,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_21626266 = ref object of OpenApiRestCall_21625435
proc url_CreateAccount_21626268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAccount_21626267(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626269 = header.getOrDefault("X-Amz-Date")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Date", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Security-Token", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Algorithm", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Signature")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Signature", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Credential")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Credential", valid_21626275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626277: Call_CreateAccount_21626266; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_21626277.validator(path, query, header, formData, body, _)
  let scheme = call_21626277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626277.makeUrl(scheme.get, call_21626277.host, call_21626277.base,
                               call_21626277.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626277, uri, valid, _)

proc call*(call_21626278: Call_CreateAccount_21626266; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_21626279 = newJObject()
  if body != nil:
    body_21626279 = body
  result = call_21626278.call(nil, nil, nil, nil, body_21626279)

var createAccount* = Call_CreateAccount_21626266(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_21626267, base: "/",
    makeUrl: url_CreateAccount_21626268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_21626247 = ref object of OpenApiRestCall_21625435
proc url_ListAccounts_21626249(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_21626248(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626250 = query.getOrDefault("user-email")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "user-email", valid_21626250
  var valid_21626251 = query.getOrDefault("NextToken")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "NextToken", valid_21626251
  var valid_21626252 = query.getOrDefault("name")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "name", valid_21626252
  var valid_21626253 = query.getOrDefault("max-results")
  valid_21626253 = validateParameter(valid_21626253, JInt, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "max-results", valid_21626253
  var valid_21626254 = query.getOrDefault("next-token")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "next-token", valid_21626254
  var valid_21626255 = query.getOrDefault("MaxResults")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "MaxResults", valid_21626255
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
  var valid_21626256 = header.getOrDefault("X-Amz-Date")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Date", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Security-Token", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Algorithm", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Signature")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Signature", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Credential")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Credential", valid_21626262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626263: Call_ListAccounts_21626247; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_21626263.validator(path, query, header, formData, body, _)
  let scheme = call_21626263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626263.makeUrl(scheme.get, call_21626263.host, call_21626263.base,
                               call_21626263.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626263, uri, valid, _)

proc call*(call_21626264: Call_ListAccounts_21626247; userEmail: string = "";
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
  var query_21626265 = newJObject()
  add(query_21626265, "user-email", newJString(userEmail))
  add(query_21626265, "NextToken", newJString(NextToken))
  add(query_21626265, "name", newJString(name))
  add(query_21626265, "max-results", newJInt(maxResults))
  add(query_21626265, "next-token", newJString(nextToken))
  add(query_21626265, "MaxResults", newJString(MaxResults))
  result = call_21626264.call(nil, query_21626265, nil, nil, nil)

var listAccounts* = Call_ListAccounts_21626247(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_21626248, base: "/", makeUrl: url_ListAccounts_21626249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAttendee_21626299 = ref object of OpenApiRestCall_21625435
proc url_CreateAttendee_21626301(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAttendee_21626300(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_21626302 = path.getOrDefault("meetingId")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "meetingId", valid_21626302
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
  var valid_21626303 = header.getOrDefault("X-Amz-Date")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Date", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Security-Token", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_CreateAttendee_21626299; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_CreateAttendee_21626299; body: JsonNode;
          meetingId: string): Recallable =
  ## createAttendee
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_21626313 = newJObject()
  var body_21626314 = newJObject()
  if body != nil:
    body_21626314 = body
  add(path_21626313, "meetingId", newJString(meetingId))
  result = call_21626312.call(path_21626313, nil, nil, nil, body_21626314)

var createAttendee* = Call_CreateAttendee_21626299(name: "createAttendee",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_CreateAttendee_21626300,
    base: "/", makeUrl: url_CreateAttendee_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttendees_21626280 = ref object of OpenApiRestCall_21625435
proc url_ListAttendees_21626282(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttendees_21626281(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_21626283 = path.getOrDefault("meetingId")
  valid_21626283 = validateParameter(valid_21626283, JString, required = true,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "meetingId", valid_21626283
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
  var valid_21626284 = query.getOrDefault("NextToken")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "NextToken", valid_21626284
  var valid_21626285 = query.getOrDefault("max-results")
  valid_21626285 = validateParameter(valid_21626285, JInt, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "max-results", valid_21626285
  var valid_21626286 = query.getOrDefault("next-token")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "next-token", valid_21626286
  var valid_21626287 = query.getOrDefault("MaxResults")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "MaxResults", valid_21626287
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
  var valid_21626288 = header.getOrDefault("X-Amz-Date")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Date", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Security-Token", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626295: Call_ListAttendees_21626280; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626295.validator(path, query, header, formData, body, _)
  let scheme = call_21626295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626295.makeUrl(scheme.get, call_21626295.host, call_21626295.base,
                               call_21626295.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626295, uri, valid, _)

proc call*(call_21626296: Call_ListAttendees_21626280; meetingId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listAttendees
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626297 = newJObject()
  var query_21626298 = newJObject()
  add(query_21626298, "NextToken", newJString(NextToken))
  add(query_21626298, "max-results", newJInt(maxResults))
  add(query_21626298, "next-token", newJString(nextToken))
  add(path_21626297, "meetingId", newJString(meetingId))
  add(query_21626298, "MaxResults", newJString(MaxResults))
  result = call_21626296.call(path_21626297, query_21626298, nil, nil, nil)

var listAttendees* = Call_ListAttendees_21626280(name: "listAttendees",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_ListAttendees_21626281,
    base: "/", makeUrl: url_ListAttendees_21626282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_21626334 = ref object of OpenApiRestCall_21625435
proc url_CreateBot_21626336(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateBot_21626335(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626337 = path.getOrDefault("accountId")
  valid_21626337 = validateParameter(valid_21626337, JString, required = true,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "accountId", valid_21626337
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
  var valid_21626338 = header.getOrDefault("X-Amz-Date")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Date", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Security-Token", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Algorithm", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Signature")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Signature", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Credential")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Credential", valid_21626344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626346: Call_CreateBot_21626334; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_21626346.validator(path, query, header, formData, body, _)
  let scheme = call_21626346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626346.makeUrl(scheme.get, call_21626346.host, call_21626346.base,
                               call_21626346.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626346, uri, valid, _)

proc call*(call_21626347: Call_CreateBot_21626334; accountId: string; body: JsonNode): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_21626348 = newJObject()
  var body_21626349 = newJObject()
  add(path_21626348, "accountId", newJString(accountId))
  if body != nil:
    body_21626349 = body
  result = call_21626347.call(path_21626348, nil, nil, nil, body_21626349)

var createBot* = Call_CreateBot_21626334(name: "createBot",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/bots",
                                      validator: validate_CreateBot_21626335,
                                      base: "/", makeUrl: url_CreateBot_21626336,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_21626315 = ref object of OpenApiRestCall_21625435
proc url_ListBots_21626317(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListBots_21626316(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626318 = path.getOrDefault("accountId")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "accountId", valid_21626318
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. The default is 10.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626319 = query.getOrDefault("NextToken")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "NextToken", valid_21626319
  var valid_21626320 = query.getOrDefault("max-results")
  valid_21626320 = validateParameter(valid_21626320, JInt, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "max-results", valid_21626320
  var valid_21626321 = query.getOrDefault("next-token")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "next-token", valid_21626321
  var valid_21626322 = query.getOrDefault("MaxResults")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "MaxResults", valid_21626322
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
  var valid_21626323 = header.getOrDefault("X-Amz-Date")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Date", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Security-Token", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Algorithm", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Signature")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Signature", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Credential")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Credential", valid_21626329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626330: Call_ListBots_21626315; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_21626330.validator(path, query, header, formData, body, _)
  let scheme = call_21626330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626330.makeUrl(scheme.get, call_21626330.host, call_21626330.base,
                               call_21626330.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626330, uri, valid, _)

proc call*(call_21626331: Call_ListBots_21626315; accountId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listBots
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. The default is 10.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626332 = newJObject()
  var query_21626333 = newJObject()
  add(path_21626332, "accountId", newJString(accountId))
  add(query_21626333, "NextToken", newJString(NextToken))
  add(query_21626333, "max-results", newJInt(maxResults))
  add(query_21626333, "next-token", newJString(nextToken))
  add(query_21626333, "MaxResults", newJString(MaxResults))
  result = call_21626331.call(path_21626332, query_21626333, nil, nil, nil)

var listBots* = Call_ListBots_21626315(name: "listBots", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_ListBots_21626316,
                                    base: "/", makeUrl: url_ListBots_21626317,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMeeting_21626367 = ref object of OpenApiRestCall_21625435
proc url_CreateMeeting_21626369(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMeeting_21626368(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
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
  var valid_21626370 = header.getOrDefault("X-Amz-Date")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Date", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Security-Token", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Algorithm", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Signature")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Signature", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Credential")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Credential", valid_21626376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626378: Call_CreateMeeting_21626367; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626378.validator(path, query, header, formData, body, _)
  let scheme = call_21626378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626378.makeUrl(scheme.get, call_21626378.host, call_21626378.base,
                               call_21626378.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626378, uri, valid, _)

proc call*(call_21626379: Call_CreateMeeting_21626367; body: JsonNode): Recallable =
  ## createMeeting
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  var body_21626380 = newJObject()
  if body != nil:
    body_21626380 = body
  result = call_21626379.call(nil, nil, nil, nil, body_21626380)

var createMeeting* = Call_CreateMeeting_21626367(name: "createMeeting",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_CreateMeeting_21626368, base: "/",
    makeUrl: url_CreateMeeting_21626369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeetings_21626350 = ref object of OpenApiRestCall_21625435
proc url_ListMeetings_21626352(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeetings_21626351(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
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
  var valid_21626353 = query.getOrDefault("NextToken")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "NextToken", valid_21626353
  var valid_21626354 = query.getOrDefault("max-results")
  valid_21626354 = validateParameter(valid_21626354, JInt, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "max-results", valid_21626354
  var valid_21626355 = query.getOrDefault("next-token")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "next-token", valid_21626355
  var valid_21626356 = query.getOrDefault("MaxResults")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "MaxResults", valid_21626356
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
  var valid_21626357 = header.getOrDefault("X-Amz-Date")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Date", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Security-Token", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Algorithm", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Signature")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Signature", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Credential")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Credential", valid_21626363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626364: Call_ListMeetings_21626350; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626364.validator(path, query, header, formData, body, _)
  let scheme = call_21626364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626364.makeUrl(scheme.get, call_21626364.host, call_21626364.base,
                               call_21626364.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626364, uri, valid, _)

proc call*(call_21626365: Call_ListMeetings_21626350; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listMeetings
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626366 = newJObject()
  add(query_21626366, "NextToken", newJString(NextToken))
  add(query_21626366, "max-results", newJInt(maxResults))
  add(query_21626366, "next-token", newJString(nextToken))
  add(query_21626366, "MaxResults", newJString(MaxResults))
  result = call_21626365.call(nil, query_21626366, nil, nil, nil)

var listMeetings* = Call_ListMeetings_21626350(name: "listMeetings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_ListMeetings_21626351, base: "/", makeUrl: url_ListMeetings_21626352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_21626398 = ref object of OpenApiRestCall_21625435
proc url_CreatePhoneNumberOrder_21626400(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePhoneNumberOrder_21626399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
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
  var valid_21626401 = header.getOrDefault("X-Amz-Date")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Date", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Security-Token", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Algorithm", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Signature")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Signature", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Credential")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Credential", valid_21626407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626409: Call_CreatePhoneNumberOrder_21626398;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_21626409.validator(path, query, header, formData, body, _)
  let scheme = call_21626409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626409.makeUrl(scheme.get, call_21626409.host, call_21626409.base,
                               call_21626409.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626409, uri, valid, _)

proc call*(call_21626410: Call_CreatePhoneNumberOrder_21626398; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_21626411 = newJObject()
  if body != nil:
    body_21626411 = body
  result = call_21626410.call(nil, nil, nil, nil, body_21626411)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_21626398(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_21626399, base: "/",
    makeUrl: url_CreatePhoneNumberOrder_21626400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_21626381 = ref object of OpenApiRestCall_21625435
proc url_ListPhoneNumberOrders_21626383(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumberOrders_21626382(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626384 = query.getOrDefault("NextToken")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "NextToken", valid_21626384
  var valid_21626385 = query.getOrDefault("max-results")
  valid_21626385 = validateParameter(valid_21626385, JInt, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "max-results", valid_21626385
  var valid_21626386 = query.getOrDefault("next-token")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "next-token", valid_21626386
  var valid_21626387 = query.getOrDefault("MaxResults")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "MaxResults", valid_21626387
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
  var valid_21626388 = header.getOrDefault("X-Amz-Date")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Date", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-Security-Token", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Algorithm", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Signature")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Signature", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Credential")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Credential", valid_21626394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626395: Call_ListPhoneNumberOrders_21626381;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_21626395.validator(path, query, header, formData, body, _)
  let scheme = call_21626395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626395.makeUrl(scheme.get, call_21626395.host, call_21626395.base,
                               call_21626395.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626395, uri, valid, _)

proc call*(call_21626396: Call_ListPhoneNumberOrders_21626381;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
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
  var query_21626397 = newJObject()
  add(query_21626397, "NextToken", newJString(NextToken))
  add(query_21626397, "max-results", newJInt(maxResults))
  add(query_21626397, "next-token", newJString(nextToken))
  add(query_21626397, "MaxResults", newJString(MaxResults))
  result = call_21626396.call(nil, query_21626397, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_21626381(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_21626382, base: "/",
    makeUrl: url_ListPhoneNumberOrders_21626383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_21626432 = ref object of OpenApiRestCall_21625435
proc url_CreateRoom_21626434(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateRoom_21626433(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a chat room for the specified Amazon Chime Enterprise account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626435 = path.getOrDefault("accountId")
  valid_21626435 = validateParameter(valid_21626435, JString, required = true,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "accountId", valid_21626435
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
  var valid_21626436 = header.getOrDefault("X-Amz-Date")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Date", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Security-Token", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Algorithm", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Signature")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Signature", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Credential")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Credential", valid_21626442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626444: Call_CreateRoom_21626432; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a chat room for the specified Amazon Chime Enterprise account.
  ## 
  let valid = call_21626444.validator(path, query, header, formData, body, _)
  let scheme = call_21626444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626444.makeUrl(scheme.get, call_21626444.host, call_21626444.base,
                               call_21626444.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626444, uri, valid, _)

proc call*(call_21626445: Call_CreateRoom_21626432; accountId: string; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a chat room for the specified Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_21626446 = newJObject()
  var body_21626447 = newJObject()
  add(path_21626446, "accountId", newJString(accountId))
  if body != nil:
    body_21626447 = body
  result = call_21626445.call(path_21626446, nil, nil, nil, body_21626447)

var createRoom* = Call_CreateRoom_21626432(name: "createRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com",
                                        route: "/accounts/{accountId}/rooms",
                                        validator: validate_CreateRoom_21626433,
                                        base: "/", makeUrl: url_CreateRoom_21626434,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRooms_21626412 = ref object of OpenApiRestCall_21625435
proc url_ListRooms_21626414(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListRooms_21626413(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626415 = path.getOrDefault("accountId")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "accountId", valid_21626415
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   member-id: JString
  ##            : The member ID (user ID or bot ID).
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626416 = query.getOrDefault("NextToken")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "NextToken", valid_21626416
  var valid_21626417 = query.getOrDefault("member-id")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "member-id", valid_21626417
  var valid_21626418 = query.getOrDefault("max-results")
  valid_21626418 = validateParameter(valid_21626418, JInt, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "max-results", valid_21626418
  var valid_21626419 = query.getOrDefault("next-token")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "next-token", valid_21626419
  var valid_21626420 = query.getOrDefault("MaxResults")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "MaxResults", valid_21626420
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
  var valid_21626421 = header.getOrDefault("X-Amz-Date")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Date", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Security-Token", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Algorithm", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Signature")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Signature", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Credential")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Credential", valid_21626427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626428: Call_ListRooms_21626412; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  let valid = call_21626428.validator(path, query, header, formData, body, _)
  let scheme = call_21626428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626428.makeUrl(scheme.get, call_21626428.host, call_21626428.base,
                               call_21626428.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626428, uri, valid, _)

proc call*(call_21626429: Call_ListRooms_21626412; accountId: string;
          NextToken: string = ""; memberId: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRooms
  ## Lists the room details for the specified Amazon Chime Enterprise account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   memberId: string
  ##           : The member ID (user ID or bot ID).
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626430 = newJObject()
  var query_21626431 = newJObject()
  add(path_21626430, "accountId", newJString(accountId))
  add(query_21626431, "NextToken", newJString(NextToken))
  add(query_21626431, "member-id", newJString(memberId))
  add(query_21626431, "max-results", newJInt(maxResults))
  add(query_21626431, "next-token", newJString(nextToken))
  add(query_21626431, "MaxResults", newJString(MaxResults))
  result = call_21626429.call(path_21626430, query_21626431, nil, nil, nil)

var listRooms* = Call_ListRooms_21626412(name: "listRooms", meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/rooms",
                                      validator: validate_ListRooms_21626413,
                                      base: "/", makeUrl: url_ListRooms_21626414,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoomMembership_21626468 = ref object of OpenApiRestCall_21625435
proc url_CreateRoomMembership_21626470(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoomMembership_21626469(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626471 = path.getOrDefault("accountId")
  valid_21626471 = validateParameter(valid_21626471, JString, required = true,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "accountId", valid_21626471
  var valid_21626472 = path.getOrDefault("roomId")
  valid_21626472 = validateParameter(valid_21626472, JString, required = true,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "roomId", valid_21626472
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
  var valid_21626473 = header.getOrDefault("X-Amz-Date")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Date", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Security-Token", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Algorithm", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Signature")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Signature", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Credential")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Credential", valid_21626479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626481: Call_CreateRoomMembership_21626468; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a member to a chat room in an Amazon Chime Enterprise account. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_21626481.validator(path, query, header, formData, body, _)
  let scheme = call_21626481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626481.makeUrl(scheme.get, call_21626481.host, call_21626481.base,
                               call_21626481.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626481, uri, valid, _)

proc call*(call_21626482: Call_CreateRoomMembership_21626468; accountId: string;
          body: JsonNode; roomId: string): Recallable =
  ## createRoomMembership
  ## Adds a member to a chat room in an Amazon Chime Enterprise account. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_21626483 = newJObject()
  var body_21626484 = newJObject()
  add(path_21626483, "accountId", newJString(accountId))
  if body != nil:
    body_21626484 = body
  add(path_21626483, "roomId", newJString(roomId))
  result = call_21626482.call(path_21626483, nil, nil, nil, body_21626484)

var createRoomMembership* = Call_CreateRoomMembership_21626468(
    name: "createRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_CreateRoomMembership_21626469, base: "/",
    makeUrl: url_CreateRoomMembership_21626470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoomMemberships_21626448 = ref object of OpenApiRestCall_21625435
proc url_ListRoomMemberships_21626450(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoomMemberships_21626449(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626451 = path.getOrDefault("accountId")
  valid_21626451 = validateParameter(valid_21626451, JString, required = true,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "accountId", valid_21626451
  var valid_21626452 = path.getOrDefault("roomId")
  valid_21626452 = validateParameter(valid_21626452, JString, required = true,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "roomId", valid_21626452
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
  var valid_21626453 = query.getOrDefault("NextToken")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "NextToken", valid_21626453
  var valid_21626454 = query.getOrDefault("max-results")
  valid_21626454 = validateParameter(valid_21626454, JInt, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "max-results", valid_21626454
  var valid_21626455 = query.getOrDefault("next-token")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "next-token", valid_21626455
  var valid_21626456 = query.getOrDefault("MaxResults")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "MaxResults", valid_21626456
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
  var valid_21626457 = header.getOrDefault("X-Amz-Date")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Date", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Security-Token", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Algorithm", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Signature")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Signature", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Credential")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Credential", valid_21626463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626464: Call_ListRoomMemberships_21626448; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the membership details for the specified room in an Amazon Chime Enterprise account, such as the members' IDs, email addresses, and names.
  ## 
  let valid = call_21626464.validator(path, query, header, formData, body, _)
  let scheme = call_21626464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626464.makeUrl(scheme.get, call_21626464.host, call_21626464.base,
                               call_21626464.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626464, uri, valid, _)

proc call*(call_21626465: Call_ListRoomMemberships_21626448; accountId: string;
          roomId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRoomMemberships
  ## Lists the membership details for the specified room in an Amazon Chime Enterprise account, such as the members' IDs, email addresses, and names.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   roomId: string (required)
  ##         : The room ID.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626466 = newJObject()
  var query_21626467 = newJObject()
  add(path_21626466, "accountId", newJString(accountId))
  add(query_21626467, "NextToken", newJString(NextToken))
  add(query_21626467, "max-results", newJInt(maxResults))
  add(query_21626467, "next-token", newJString(nextToken))
  add(path_21626466, "roomId", newJString(roomId))
  add(query_21626467, "MaxResults", newJString(MaxResults))
  result = call_21626465.call(path_21626466, query_21626467, nil, nil, nil)

var listRoomMemberships* = Call_ListRoomMemberships_21626448(
    name: "listRoomMemberships", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_ListRoomMemberships_21626449, base: "/",
    makeUrl: url_ListRoomMemberships_21626450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_21626485 = ref object of OpenApiRestCall_21625435
proc url_CreateUser_21626487(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateUser_21626486(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a user under the specified Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626488 = path.getOrDefault("accountId")
  valid_21626488 = validateParameter(valid_21626488, JString, required = true,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "accountId", valid_21626488
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21626489 = query.getOrDefault("operation")
  valid_21626489 = validateParameter(valid_21626489, JString, required = true,
                                   default = newJString("create"))
  if valid_21626489 != nil:
    section.add "operation", valid_21626489
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
  var valid_21626490 = header.getOrDefault("X-Amz-Date")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Date", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Security-Token", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Algorithm", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Signature")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Signature", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Credential")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Credential", valid_21626496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626498: Call_CreateUser_21626485; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user under the specified Amazon Chime account.
  ## 
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_CreateUser_21626485; accountId: string;
          body: JsonNode; operation: string = "create"): Recallable =
  ## createUser
  ## Creates a user under the specified Amazon Chime account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21626500 = newJObject()
  var query_21626501 = newJObject()
  var body_21626502 = newJObject()
  add(path_21626500, "accountId", newJString(accountId))
  add(query_21626501, "operation", newJString(operation))
  if body != nil:
    body_21626502 = body
  result = call_21626499.call(path_21626500, query_21626501, nil, nil, body_21626502)

var createUser* = Call_CreateUser_21626485(name: "createUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=create",
                                        validator: validate_CreateUser_21626486,
                                        base: "/", makeUrl: url_CreateUser_21626487,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_21626520 = ref object of OpenApiRestCall_21625435
proc url_CreateVoiceConnector_21626522(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnector_21626521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
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
  var valid_21626523 = header.getOrDefault("X-Amz-Date")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Date", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Security-Token", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Algorithm", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Signature")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Signature", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Credential")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Credential", valid_21626529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626531: Call_CreateVoiceConnector_21626520; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  let valid = call_21626531.validator(path, query, header, formData, body, _)
  let scheme = call_21626531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626531.makeUrl(scheme.get, call_21626531.host, call_21626531.base,
                               call_21626531.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626531, uri, valid, _)

proc call*(call_21626532: Call_CreateVoiceConnector_21626520; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ##   body: JObject (required)
  var body_21626533 = newJObject()
  if body != nil:
    body_21626533 = body
  result = call_21626532.call(nil, nil, nil, nil, body_21626533)

var createVoiceConnector* = Call_CreateVoiceConnector_21626520(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_21626521, base: "/",
    makeUrl: url_CreateVoiceConnector_21626522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_21626503 = ref object of OpenApiRestCall_21625435
proc url_ListVoiceConnectors_21626505(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectors_21626504(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626506 = query.getOrDefault("NextToken")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "NextToken", valid_21626506
  var valid_21626507 = query.getOrDefault("max-results")
  valid_21626507 = validateParameter(valid_21626507, JInt, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "max-results", valid_21626507
  var valid_21626508 = query.getOrDefault("next-token")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "next-token", valid_21626508
  var valid_21626509 = query.getOrDefault("MaxResults")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "MaxResults", valid_21626509
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
  var valid_21626510 = header.getOrDefault("X-Amz-Date")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Date", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Security-Token", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Algorithm", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Signature")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Signature", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Credential")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Credential", valid_21626516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626517: Call_ListVoiceConnectors_21626503; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_21626517.validator(path, query, header, formData, body, _)
  let scheme = call_21626517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626517.makeUrl(scheme.get, call_21626517.host, call_21626517.base,
                               call_21626517.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626517, uri, valid, _)

proc call*(call_21626518: Call_ListVoiceConnectors_21626503;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
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
  var query_21626519 = newJObject()
  add(query_21626519, "NextToken", newJString(NextToken))
  add(query_21626519, "max-results", newJInt(maxResults))
  add(query_21626519, "next-token", newJString(nextToken))
  add(query_21626519, "MaxResults", newJString(MaxResults))
  result = call_21626518.call(nil, query_21626519, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_21626503(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_21626504, base: "/",
    makeUrl: url_ListVoiceConnectors_21626505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnectorGroup_21626551 = ref object of OpenApiRestCall_21625435
proc url_CreateVoiceConnectorGroup_21626553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnectorGroup_21626552(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
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
  var valid_21626554 = header.getOrDefault("X-Amz-Date")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Date", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Security-Token", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Algorithm", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Signature")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Signature", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Credential")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Credential", valid_21626560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626562: Call_CreateVoiceConnectorGroup_21626551;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  let valid = call_21626562.validator(path, query, header, formData, body, _)
  let scheme = call_21626562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626562.makeUrl(scheme.get, call_21626562.host, call_21626562.base,
                               call_21626562.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626562, uri, valid, _)

proc call*(call_21626563: Call_CreateVoiceConnectorGroup_21626551; body: JsonNode): Recallable =
  ## createVoiceConnectorGroup
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ##   body: JObject (required)
  var body_21626564 = newJObject()
  if body != nil:
    body_21626564 = body
  result = call_21626563.call(nil, nil, nil, nil, body_21626564)

var createVoiceConnectorGroup* = Call_CreateVoiceConnectorGroup_21626551(
    name: "createVoiceConnectorGroup", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_CreateVoiceConnectorGroup_21626552, base: "/",
    makeUrl: url_CreateVoiceConnectorGroup_21626553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorGroups_21626534 = ref object of OpenApiRestCall_21625435
proc url_ListVoiceConnectorGroups_21626536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectorGroups_21626535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
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
  var valid_21626537 = query.getOrDefault("NextToken")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "NextToken", valid_21626537
  var valid_21626538 = query.getOrDefault("max-results")
  valid_21626538 = validateParameter(valid_21626538, JInt, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "max-results", valid_21626538
  var valid_21626539 = query.getOrDefault("next-token")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "next-token", valid_21626539
  var valid_21626540 = query.getOrDefault("MaxResults")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "MaxResults", valid_21626540
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
  var valid_21626541 = header.getOrDefault("X-Amz-Date")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Date", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Security-Token", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Algorithm", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Signature")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Signature", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Credential")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Credential", valid_21626547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626548: Call_ListVoiceConnectorGroups_21626534;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  let valid = call_21626548.validator(path, query, header, formData, body, _)
  let scheme = call_21626548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626548.makeUrl(scheme.get, call_21626548.host, call_21626548.base,
                               call_21626548.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626548, uri, valid, _)

proc call*(call_21626549: Call_ListVoiceConnectorGroups_21626534;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listVoiceConnectorGroups
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626550 = newJObject()
  add(query_21626550, "NextToken", newJString(NextToken))
  add(query_21626550, "max-results", newJInt(maxResults))
  add(query_21626550, "next-token", newJString(nextToken))
  add(query_21626550, "MaxResults", newJString(MaxResults))
  result = call_21626549.call(nil, query_21626550, nil, nil, nil)

var listVoiceConnectorGroups* = Call_ListVoiceConnectorGroups_21626534(
    name: "listVoiceConnectorGroups", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_ListVoiceConnectorGroups_21626535, base: "/",
    makeUrl: url_ListVoiceConnectorGroups_21626536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_21626579 = ref object of OpenApiRestCall_21625435
proc url_UpdateAccount_21626581(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_21626580(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626582 = path.getOrDefault("accountId")
  valid_21626582 = validateParameter(valid_21626582, JString, required = true,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "accountId", valid_21626582
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
  var valid_21626583 = header.getOrDefault("X-Amz-Date")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Date", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Security-Token", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Algorithm", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Signature")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Signature", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Credential")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Credential", valid_21626589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626591: Call_UpdateAccount_21626579; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_21626591.validator(path, query, header, formData, body, _)
  let scheme = call_21626591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626591.makeUrl(scheme.get, call_21626591.host, call_21626591.base,
                               call_21626591.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626591, uri, valid, _)

proc call*(call_21626592: Call_UpdateAccount_21626579; accountId: string;
          body: JsonNode): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_21626593 = newJObject()
  var body_21626594 = newJObject()
  add(path_21626593, "accountId", newJString(accountId))
  if body != nil:
    body_21626594 = body
  result = call_21626592.call(path_21626593, nil, nil, nil, body_21626594)

var updateAccount* = Call_UpdateAccount_21626579(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_21626580,
    base: "/", makeUrl: url_UpdateAccount_21626581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_21626565 = ref object of OpenApiRestCall_21625435
proc url_GetAccount_21626567(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccount_21626566(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626568 = path.getOrDefault("accountId")
  valid_21626568 = validateParameter(valid_21626568, JString, required = true,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "accountId", valid_21626568
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
  var valid_21626569 = header.getOrDefault("X-Amz-Date")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Date", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Security-Token", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Algorithm", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Signature")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Signature", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Credential")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Credential", valid_21626575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626576: Call_GetAccount_21626565; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_21626576.validator(path, query, header, formData, body, _)
  let scheme = call_21626576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626576.makeUrl(scheme.get, call_21626576.host, call_21626576.base,
                               call_21626576.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626576, uri, valid, _)

proc call*(call_21626577: Call_GetAccount_21626565; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_21626578 = newJObject()
  add(path_21626578, "accountId", newJString(accountId))
  result = call_21626577.call(path_21626578, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_21626565(name: "getAccount",
                                        meth: HttpMethod.HttpGet,
                                        host: "chime.amazonaws.com",
                                        route: "/accounts/{accountId}",
                                        validator: validate_GetAccount_21626566,
                                        base: "/", makeUrl: url_GetAccount_21626567,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_21626595 = ref object of OpenApiRestCall_21625435
proc url_DeleteAccount_21626597(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccount_21626596(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21626598 = path.getOrDefault("accountId")
  valid_21626598 = validateParameter(valid_21626598, JString, required = true,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "accountId", valid_21626598
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
  var valid_21626599 = header.getOrDefault("X-Amz-Date")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Date", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Security-Token", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Algorithm", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Signature")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Signature", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Credential")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Credential", valid_21626605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626606: Call_DeleteAccount_21626595; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_21626606.validator(path, query, header, formData, body, _)
  let scheme = call_21626606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626606.makeUrl(scheme.get, call_21626606.host, call_21626606.base,
                               call_21626606.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626606, uri, valid, _)

proc call*(call_21626607: Call_DeleteAccount_21626595; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_21626608 = newJObject()
  add(path_21626608, "accountId", newJString(accountId))
  result = call_21626607.call(path_21626608, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_21626595(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_21626596,
    base: "/", makeUrl: url_DeleteAccount_21626597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttendee_21626609 = ref object of OpenApiRestCall_21625435
proc url_GetAttendee_21626611(protocol: Scheme; host: string; base: string;
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

proc validate_GetAttendee_21626610(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626612 = path.getOrDefault("attendeeId")
  valid_21626612 = validateParameter(valid_21626612, JString, required = true,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "attendeeId", valid_21626612
  var valid_21626613 = path.getOrDefault("meetingId")
  valid_21626613 = validateParameter(valid_21626613, JString, required = true,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "meetingId", valid_21626613
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
  var valid_21626614 = header.getOrDefault("X-Amz-Date")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Date", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Security-Token", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Algorithm", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Signature")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Signature", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Credential")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Credential", valid_21626620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626621: Call_GetAttendee_21626609; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626621.validator(path, query, header, formData, body, _)
  let scheme = call_21626621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626621.makeUrl(scheme.get, call_21626621.host, call_21626621.base,
                               call_21626621.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626621, uri, valid, _)

proc call*(call_21626622: Call_GetAttendee_21626609; attendeeId: string;
          meetingId: string): Recallable =
  ## getAttendee
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_21626623 = newJObject()
  add(path_21626623, "attendeeId", newJString(attendeeId))
  add(path_21626623, "meetingId", newJString(meetingId))
  result = call_21626622.call(path_21626623, nil, nil, nil, nil)

var getAttendee* = Call_GetAttendee_21626609(name: "getAttendee",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees/{attendeeId}",
    validator: validate_GetAttendee_21626610, base: "/", makeUrl: url_GetAttendee_21626611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttendee_21626624 = ref object of OpenApiRestCall_21625435
proc url_DeleteAttendee_21626626(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAttendee_21626625(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626627 = path.getOrDefault("attendeeId")
  valid_21626627 = validateParameter(valid_21626627, JString, required = true,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "attendeeId", valid_21626627
  var valid_21626628 = path.getOrDefault("meetingId")
  valid_21626628 = validateParameter(valid_21626628, JString, required = true,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "meetingId", valid_21626628
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
  var valid_21626629 = header.getOrDefault("X-Amz-Date")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Date", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Security-Token", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Algorithm", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Signature")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Signature", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Credential")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Credential", valid_21626635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626636: Call_DeleteAttendee_21626624; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626636.validator(path, query, header, formData, body, _)
  let scheme = call_21626636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626636.makeUrl(scheme.get, call_21626636.host, call_21626636.base,
                               call_21626636.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626636, uri, valid, _)

proc call*(call_21626637: Call_DeleteAttendee_21626624; attendeeId: string;
          meetingId: string): Recallable =
  ## deleteAttendee
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_21626638 = newJObject()
  add(path_21626638, "attendeeId", newJString(attendeeId))
  add(path_21626638, "meetingId", newJString(meetingId))
  result = call_21626637.call(path_21626638, nil, nil, nil, nil)

var deleteAttendee* = Call_DeleteAttendee_21626624(name: "deleteAttendee",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees/{attendeeId}",
    validator: validate_DeleteAttendee_21626625, base: "/",
    makeUrl: url_DeleteAttendee_21626626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_21626654 = ref object of OpenApiRestCall_21625435
proc url_PutEventsConfiguration_21626656(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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
               (kind: VariableSegment, value: "botId"),
               (kind: ConstantSegment, value: "/events-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEventsConfiguration_21626655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626657 = path.getOrDefault("accountId")
  valid_21626657 = validateParameter(valid_21626657, JString, required = true,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "accountId", valid_21626657
  var valid_21626658 = path.getOrDefault("botId")
  valid_21626658 = validateParameter(valid_21626658, JString, required = true,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "botId", valid_21626658
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
  var valid_21626659 = header.getOrDefault("X-Amz-Date")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Date", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Security-Token", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Algorithm", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Signature")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Signature", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Credential")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Credential", valid_21626665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626667: Call_PutEventsConfiguration_21626654;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_21626667.validator(path, query, header, formData, body, _)
  let scheme = call_21626667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626667.makeUrl(scheme.get, call_21626667.host, call_21626667.base,
                               call_21626667.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626667, uri, valid, _)

proc call*(call_21626668: Call_PutEventsConfiguration_21626654; accountId: string;
          botId: string; body: JsonNode): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_21626669 = newJObject()
  var body_21626670 = newJObject()
  add(path_21626669, "accountId", newJString(accountId))
  add(path_21626669, "botId", newJString(botId))
  if body != nil:
    body_21626670 = body
  result = call_21626668.call(path_21626669, nil, nil, nil, body_21626670)

var putEventsConfiguration* = Call_PutEventsConfiguration_21626654(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_21626655, base: "/",
    makeUrl: url_PutEventsConfiguration_21626656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_21626639 = ref object of OpenApiRestCall_21625435
proc url_GetEventsConfiguration_21626641(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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
               (kind: VariableSegment, value: "botId"),
               (kind: ConstantSegment, value: "/events-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventsConfiguration_21626640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626642 = path.getOrDefault("accountId")
  valid_21626642 = validateParameter(valid_21626642, JString, required = true,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "accountId", valid_21626642
  var valid_21626643 = path.getOrDefault("botId")
  valid_21626643 = validateParameter(valid_21626643, JString, required = true,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "botId", valid_21626643
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
  var valid_21626644 = header.getOrDefault("X-Amz-Date")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Date", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Security-Token", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Algorithm", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Signature")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Signature", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Credential")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Credential", valid_21626650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626651: Call_GetEventsConfiguration_21626639;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_GetEventsConfiguration_21626639; accountId: string;
          botId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_21626653 = newJObject()
  add(path_21626653, "accountId", newJString(accountId))
  add(path_21626653, "botId", newJString(botId))
  result = call_21626652.call(path_21626653, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_21626639(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_21626640, base: "/",
    makeUrl: url_GetEventsConfiguration_21626641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_21626671 = ref object of OpenApiRestCall_21625435
proc url_DeleteEventsConfiguration_21626673(protocol: Scheme; host: string;
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

proc validate_DeleteEventsConfiguration_21626672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626674 = path.getOrDefault("accountId")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "accountId", valid_21626674
  var valid_21626675 = path.getOrDefault("botId")
  valid_21626675 = validateParameter(valid_21626675, JString, required = true,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "botId", valid_21626675
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
  var valid_21626676 = header.getOrDefault("X-Amz-Date")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Date", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Security-Token", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Algorithm", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Signature")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Signature", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Credential")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Credential", valid_21626682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626683: Call_DeleteEventsConfiguration_21626671;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_21626683.validator(path, query, header, formData, body, _)
  let scheme = call_21626683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626683.makeUrl(scheme.get, call_21626683.host, call_21626683.base,
                               call_21626683.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626683, uri, valid, _)

proc call*(call_21626684: Call_DeleteEventsConfiguration_21626671;
          accountId: string; botId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_21626685 = newJObject()
  add(path_21626685, "accountId", newJString(accountId))
  add(path_21626685, "botId", newJString(botId))
  result = call_21626684.call(path_21626685, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_21626671(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_21626672, base: "/",
    makeUrl: url_DeleteEventsConfiguration_21626673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMeeting_21626686 = ref object of OpenApiRestCall_21625435
proc url_GetMeeting_21626688(protocol: Scheme; host: string; base: string;
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

proc validate_GetMeeting_21626687(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_21626689 = path.getOrDefault("meetingId")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "meetingId", valid_21626689
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
  var valid_21626690 = header.getOrDefault("X-Amz-Date")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Date", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Security-Token", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Algorithm", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Signature")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Signature", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Credential")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Credential", valid_21626696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626697: Call_GetMeeting_21626686; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626697.validator(path, query, header, formData, body, _)
  let scheme = call_21626697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626697.makeUrl(scheme.get, call_21626697.host, call_21626697.base,
                               call_21626697.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626697, uri, valid, _)

proc call*(call_21626698: Call_GetMeeting_21626686; meetingId: string): Recallable =
  ## getMeeting
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_21626699 = newJObject()
  add(path_21626699, "meetingId", newJString(meetingId))
  result = call_21626698.call(path_21626699, nil, nil, nil, nil)

var getMeeting* = Call_GetMeeting_21626686(name: "getMeeting",
                                        meth: HttpMethod.HttpGet,
                                        host: "chime.amazonaws.com",
                                        route: "/meetings/{meetingId}",
                                        validator: validate_GetMeeting_21626687,
                                        base: "/", makeUrl: url_GetMeeting_21626688,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMeeting_21626700 = ref object of OpenApiRestCall_21625435
proc url_DeleteMeeting_21626702(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMeeting_21626701(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meetingId: JString (required)
  ##            : The Amazon Chime SDK meeting ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meetingId` field"
  var valid_21626703 = path.getOrDefault("meetingId")
  valid_21626703 = validateParameter(valid_21626703, JString, required = true,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "meetingId", valid_21626703
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
  var valid_21626704 = header.getOrDefault("X-Amz-Date")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-Date", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Security-Token", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Algorithm", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Signature")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Signature", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Credential")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Credential", valid_21626710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626711: Call_DeleteMeeting_21626700; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_21626711.validator(path, query, header, formData, body, _)
  let scheme = call_21626711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626711.makeUrl(scheme.get, call_21626711.host, call_21626711.base,
                               call_21626711.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626711, uri, valid, _)

proc call*(call_21626712: Call_DeleteMeeting_21626700; meetingId: string): Recallable =
  ## deleteMeeting
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_21626713 = newJObject()
  add(path_21626713, "meetingId", newJString(meetingId))
  result = call_21626712.call(path_21626713, nil, nil, nil, nil)

var deleteMeeting* = Call_DeleteMeeting_21626700(name: "deleteMeeting",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}", validator: validate_DeleteMeeting_21626701,
    base: "/", makeUrl: url_DeleteMeeting_21626702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_21626728 = ref object of OpenApiRestCall_21625435
proc url_UpdatePhoneNumber_21626730(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePhoneNumber_21626729(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626731 = path.getOrDefault("phoneNumberId")
  valid_21626731 = validateParameter(valid_21626731, JString, required = true,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "phoneNumberId", valid_21626731
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
  var valid_21626732 = header.getOrDefault("X-Amz-Date")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Date", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Security-Token", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Algorithm", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Signature")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Signature", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Credential")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Credential", valid_21626738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626740: Call_UpdatePhoneNumber_21626728; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_21626740.validator(path, query, header, formData, body, _)
  let scheme = call_21626740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626740.makeUrl(scheme.get, call_21626740.host, call_21626740.base,
                               call_21626740.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626740, uri, valid, _)

proc call*(call_21626741: Call_UpdatePhoneNumber_21626728; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_21626742 = newJObject()
  var body_21626743 = newJObject()
  add(path_21626742, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_21626743 = body
  result = call_21626741.call(path_21626742, nil, nil, nil, body_21626743)

var updatePhoneNumber* = Call_UpdatePhoneNumber_21626728(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_21626729, base: "/",
    makeUrl: url_UpdatePhoneNumber_21626730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_21626714 = ref object of OpenApiRestCall_21625435
proc url_GetPhoneNumber_21626716(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumber_21626715(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626717 = path.getOrDefault("phoneNumberId")
  valid_21626717 = validateParameter(valid_21626717, JString, required = true,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "phoneNumberId", valid_21626717
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
  var valid_21626718 = header.getOrDefault("X-Amz-Date")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Date", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "X-Amz-Security-Token", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Algorithm", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Signature")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Signature", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Credential")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Credential", valid_21626724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626725: Call_GetPhoneNumber_21626714; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_21626725.validator(path, query, header, formData, body, _)
  let scheme = call_21626725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626725.makeUrl(scheme.get, call_21626725.host, call_21626725.base,
                               call_21626725.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626725, uri, valid, _)

proc call*(call_21626726: Call_GetPhoneNumber_21626714; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_21626727 = newJObject()
  add(path_21626727, "phoneNumberId", newJString(phoneNumberId))
  result = call_21626726.call(path_21626727, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_21626714(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_21626715,
    base: "/", makeUrl: url_GetPhoneNumber_21626716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_21626744 = ref object of OpenApiRestCall_21625435
proc url_DeletePhoneNumber_21626746(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePhoneNumber_21626745(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626747 = path.getOrDefault("phoneNumberId")
  valid_21626747 = validateParameter(valid_21626747, JString, required = true,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "phoneNumberId", valid_21626747
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
  var valid_21626748 = header.getOrDefault("X-Amz-Date")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Date", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Security-Token", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Algorithm", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Signature")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Signature", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Credential")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Credential", valid_21626754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626755: Call_DeletePhoneNumber_21626744; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_21626755.validator(path, query, header, formData, body, _)
  let scheme = call_21626755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626755.makeUrl(scheme.get, call_21626755.host, call_21626755.base,
                               call_21626755.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626755, uri, valid, _)

proc call*(call_21626756: Call_DeletePhoneNumber_21626744; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_21626757 = newJObject()
  add(path_21626757, "phoneNumberId", newJString(phoneNumberId))
  result = call_21626756.call(path_21626757, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_21626744(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_21626745, base: "/",
    makeUrl: url_DeletePhoneNumber_21626746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_21626773 = ref object of OpenApiRestCall_21625435
proc url_UpdateRoom_21626775(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "roomId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoom_21626774(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626776 = path.getOrDefault("accountId")
  valid_21626776 = validateParameter(valid_21626776, JString, required = true,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "accountId", valid_21626776
  var valid_21626777 = path.getOrDefault("roomId")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "roomId", valid_21626777
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
  var valid_21626778 = header.getOrDefault("X-Amz-Date")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Date", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Security-Token", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Algorithm", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Signature")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Signature", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Credential")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Credential", valid_21626784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626786: Call_UpdateRoom_21626773; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_21626786.validator(path, query, header, formData, body, _)
  let scheme = call_21626786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626786.makeUrl(scheme.get, call_21626786.host, call_21626786.base,
                               call_21626786.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626786, uri, valid, _)

proc call*(call_21626787: Call_UpdateRoom_21626773; accountId: string;
          body: JsonNode; roomId: string): Recallable =
  ## updateRoom
  ## Updates room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_21626788 = newJObject()
  var body_21626789 = newJObject()
  add(path_21626788, "accountId", newJString(accountId))
  if body != nil:
    body_21626789 = body
  add(path_21626788, "roomId", newJString(roomId))
  result = call_21626787.call(path_21626788, nil, nil, nil, body_21626789)

var updateRoom* = Call_UpdateRoom_21626773(name: "updateRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                        validator: validate_UpdateRoom_21626774,
                                        base: "/", makeUrl: url_UpdateRoom_21626775,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_21626758 = ref object of OpenApiRestCall_21625435
proc url_GetRoom_21626760(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoom_21626759(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626761 = path.getOrDefault("accountId")
  valid_21626761 = validateParameter(valid_21626761, JString, required = true,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "accountId", valid_21626761
  var valid_21626762 = path.getOrDefault("roomId")
  valid_21626762 = validateParameter(valid_21626762, JString, required = true,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "roomId", valid_21626762
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
  var valid_21626763 = header.getOrDefault("X-Amz-Date")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Date", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Security-Token", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Algorithm", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Signature")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Signature", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Credential")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Credential", valid_21626769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626770: Call_GetRoom_21626758; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_21626770.validator(path, query, header, formData, body, _)
  let scheme = call_21626770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626770.makeUrl(scheme.get, call_21626770.host, call_21626770.base,
                               call_21626770.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626770, uri, valid, _)

proc call*(call_21626771: Call_GetRoom_21626758; accountId: string; roomId: string): Recallable =
  ## getRoom
  ## Retrieves room details, such as the room name, for a room in an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_21626772 = newJObject()
  add(path_21626772, "accountId", newJString(accountId))
  add(path_21626772, "roomId", newJString(roomId))
  result = call_21626771.call(path_21626772, nil, nil, nil, nil)

var getRoom* = Call_GetRoom_21626758(name: "getRoom", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                  validator: validate_GetRoom_21626759, base: "/",
                                  makeUrl: url_GetRoom_21626760,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_21626790 = ref object of OpenApiRestCall_21625435
proc url_DeleteRoom_21626792(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "roomId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoom_21626791(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626793 = path.getOrDefault("accountId")
  valid_21626793 = validateParameter(valid_21626793, JString, required = true,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "accountId", valid_21626793
  var valid_21626794 = path.getOrDefault("roomId")
  valid_21626794 = validateParameter(valid_21626794, JString, required = true,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "roomId", valid_21626794
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
  var valid_21626795 = header.getOrDefault("X-Amz-Date")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Date", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Security-Token", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Algorithm", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Signature")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Signature", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-Credential")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-Credential", valid_21626801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626802: Call_DeleteRoom_21626790; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a chat room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_21626802.validator(path, query, header, formData, body, _)
  let scheme = call_21626802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626802.makeUrl(scheme.get, call_21626802.host, call_21626802.base,
                               call_21626802.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626802, uri, valid, _)

proc call*(call_21626803: Call_DeleteRoom_21626790; accountId: string; roomId: string): Recallable =
  ## deleteRoom
  ## Deletes a chat room in an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The chat room ID.
  var path_21626804 = newJObject()
  add(path_21626804, "accountId", newJString(accountId))
  add(path_21626804, "roomId", newJString(roomId))
  result = call_21626803.call(path_21626804, nil, nil, nil, nil)

var deleteRoom* = Call_DeleteRoom_21626790(name: "deleteRoom",
                                        meth: HttpMethod.HttpDelete,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                        validator: validate_DeleteRoom_21626791,
                                        base: "/", makeUrl: url_DeleteRoom_21626792,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoomMembership_21626805 = ref object of OpenApiRestCall_21625435
proc url_UpdateRoomMembership_21626807(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoomMembership_21626806(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626808 = path.getOrDefault("memberId")
  valid_21626808 = validateParameter(valid_21626808, JString, required = true,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "memberId", valid_21626808
  var valid_21626809 = path.getOrDefault("accountId")
  valid_21626809 = validateParameter(valid_21626809, JString, required = true,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "accountId", valid_21626809
  var valid_21626810 = path.getOrDefault("roomId")
  valid_21626810 = validateParameter(valid_21626810, JString, required = true,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "roomId", valid_21626810
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
  var valid_21626811 = header.getOrDefault("X-Amz-Date")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Date", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Security-Token", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Algorithm", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-Signature")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Signature", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Credential")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Credential", valid_21626817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626819: Call_UpdateRoomMembership_21626805; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates room membership details, such as the member role, for a room in an Amazon Chime Enterprise account. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ## 
  let valid = call_21626819.validator(path, query, header, formData, body, _)
  let scheme = call_21626819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626819.makeUrl(scheme.get, call_21626819.host, call_21626819.base,
                               call_21626819.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626819, uri, valid, _)

proc call*(call_21626820: Call_UpdateRoomMembership_21626805; memberId: string;
          accountId: string; body: JsonNode; roomId: string): Recallable =
  ## updateRoomMembership
  ## Updates room membership details, such as the member role, for a room in an Amazon Chime Enterprise account. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ##   memberId: string (required)
  ##           : The member ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_21626821 = newJObject()
  var body_21626822 = newJObject()
  add(path_21626821, "memberId", newJString(memberId))
  add(path_21626821, "accountId", newJString(accountId))
  if body != nil:
    body_21626822 = body
  add(path_21626821, "roomId", newJString(roomId))
  result = call_21626820.call(path_21626821, nil, nil, nil, body_21626822)

var updateRoomMembership* = Call_UpdateRoomMembership_21626805(
    name: "updateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_UpdateRoomMembership_21626806, base: "/",
    makeUrl: url_UpdateRoomMembership_21626807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomMembership_21626823 = ref object of OpenApiRestCall_21625435
proc url_DeleteRoomMembership_21626825(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoomMembership_21626824(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626826 = path.getOrDefault("memberId")
  valid_21626826 = validateParameter(valid_21626826, JString, required = true,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "memberId", valid_21626826
  var valid_21626827 = path.getOrDefault("accountId")
  valid_21626827 = validateParameter(valid_21626827, JString, required = true,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "accountId", valid_21626827
  var valid_21626828 = path.getOrDefault("roomId")
  valid_21626828 = validateParameter(valid_21626828, JString, required = true,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "roomId", valid_21626828
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
  var valid_21626829 = header.getOrDefault("X-Amz-Date")
  valid_21626829 = validateParameter(valid_21626829, JString, required = false,
                                   default = nil)
  if valid_21626829 != nil:
    section.add "X-Amz-Date", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Security-Token", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Algorithm", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-Signature")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-Signature", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Credential")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Credential", valid_21626835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626836: Call_DeleteRoomMembership_21626823; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a member from a chat room in an Amazon Chime Enterprise account.
  ## 
  let valid = call_21626836.validator(path, query, header, formData, body, _)
  let scheme = call_21626836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626836.makeUrl(scheme.get, call_21626836.host, call_21626836.base,
                               call_21626836.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626836, uri, valid, _)

proc call*(call_21626837: Call_DeleteRoomMembership_21626823; memberId: string;
          accountId: string; roomId: string): Recallable =
  ## deleteRoomMembership
  ## Removes a member from a chat room in an Amazon Chime Enterprise account.
  ##   memberId: string (required)
  ##           : The member ID (user ID or bot ID).
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_21626838 = newJObject()
  add(path_21626838, "memberId", newJString(memberId))
  add(path_21626838, "accountId", newJString(accountId))
  add(path_21626838, "roomId", newJString(roomId))
  result = call_21626837.call(path_21626838, nil, nil, nil, nil)

var deleteRoomMembership* = Call_DeleteRoomMembership_21626823(
    name: "deleteRoomMembership", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_DeleteRoomMembership_21626824, base: "/",
    makeUrl: url_DeleteRoomMembership_21626825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_21626853 = ref object of OpenApiRestCall_21625435
proc url_UpdateVoiceConnector_21626855(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceConnector_21626854(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626856 = path.getOrDefault("voiceConnectorId")
  valid_21626856 = validateParameter(valid_21626856, JString, required = true,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "voiceConnectorId", valid_21626856
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
  var valid_21626857 = header.getOrDefault("X-Amz-Date")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Date", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Security-Token", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Algorithm", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Signature")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Signature", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-Credential")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Credential", valid_21626863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626865: Call_UpdateVoiceConnector_21626853; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21626865.validator(path, query, header, formData, body, _)
  let scheme = call_21626865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626865.makeUrl(scheme.get, call_21626865.host, call_21626865.base,
                               call_21626865.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626865, uri, valid, _)

proc call*(call_21626866: Call_UpdateVoiceConnector_21626853;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_21626867 = newJObject()
  var body_21626868 = newJObject()
  add(path_21626867, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_21626868 = body
  result = call_21626866.call(path_21626867, nil, nil, nil, body_21626868)

var updateVoiceConnector* = Call_UpdateVoiceConnector_21626853(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_21626854, base: "/",
    makeUrl: url_UpdateVoiceConnector_21626855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_21626839 = ref object of OpenApiRestCall_21625435
proc url_GetVoiceConnector_21626841(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnector_21626840(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626842 = path.getOrDefault("voiceConnectorId")
  valid_21626842 = validateParameter(valid_21626842, JString, required = true,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "voiceConnectorId", valid_21626842
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
  var valid_21626843 = header.getOrDefault("X-Amz-Date")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Date", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-Security-Token", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Algorithm", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Signature")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-Signature", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Credential")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Credential", valid_21626849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626850: Call_GetVoiceConnector_21626839; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_21626850.validator(path, query, header, formData, body, _)
  let scheme = call_21626850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626850.makeUrl(scheme.get, call_21626850.host, call_21626850.base,
                               call_21626850.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626850, uri, valid, _)

proc call*(call_21626851: Call_GetVoiceConnector_21626839; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21626852 = newJObject()
  add(path_21626852, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21626851.call(path_21626852, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_21626839(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_21626840, base: "/",
    makeUrl: url_GetVoiceConnector_21626841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_21626869 = ref object of OpenApiRestCall_21625435
proc url_DeleteVoiceConnector_21626871(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceConnector_21626870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626872 = path.getOrDefault("voiceConnectorId")
  valid_21626872 = validateParameter(valid_21626872, JString, required = true,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "voiceConnectorId", valid_21626872
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
  var valid_21626873 = header.getOrDefault("X-Amz-Date")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Date", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Security-Token", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Algorithm", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Signature")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Signature", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-Credential")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Credential", valid_21626879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626880: Call_DeleteVoiceConnector_21626869; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  let valid = call_21626880.validator(path, query, header, formData, body, _)
  let scheme = call_21626880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626880.makeUrl(scheme.get, call_21626880.host, call_21626880.base,
                               call_21626880.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626880, uri, valid, _)

proc call*(call_21626881: Call_DeleteVoiceConnector_21626869;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21626882 = newJObject()
  add(path_21626882, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21626881.call(path_21626882, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_21626869(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_21626870, base: "/",
    makeUrl: url_DeleteVoiceConnector_21626871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnectorGroup_21626897 = ref object of OpenApiRestCall_21625435
proc url_UpdateVoiceConnectorGroup_21626899(protocol: Scheme; host: string;
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

proc validate_UpdateVoiceConnectorGroup_21626898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_21626900 = path.getOrDefault("voiceConnectorGroupId")
  valid_21626900 = validateParameter(valid_21626900, JString, required = true,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "voiceConnectorGroupId", valid_21626900
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
  var valid_21626901 = header.getOrDefault("X-Amz-Date")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Date", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Security-Token", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Algorithm", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Signature")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Signature", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Credential")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-Credential", valid_21626907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626909: Call_UpdateVoiceConnectorGroup_21626897;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  let valid = call_21626909.validator(path, query, header, formData, body, _)
  let scheme = call_21626909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626909.makeUrl(scheme.get, call_21626909.host, call_21626909.base,
                               call_21626909.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626909, uri, valid, _)

proc call*(call_21626910: Call_UpdateVoiceConnectorGroup_21626897;
          voiceConnectorGroupId: string; body: JsonNode): Recallable =
  ## updateVoiceConnectorGroup
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   body: JObject (required)
  var path_21626911 = newJObject()
  var body_21626912 = newJObject()
  add(path_21626911, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  if body != nil:
    body_21626912 = body
  result = call_21626910.call(path_21626911, nil, nil, nil, body_21626912)

var updateVoiceConnectorGroup* = Call_UpdateVoiceConnectorGroup_21626897(
    name: "updateVoiceConnectorGroup", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_UpdateVoiceConnectorGroup_21626898, base: "/",
    makeUrl: url_UpdateVoiceConnectorGroup_21626899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorGroup_21626883 = ref object of OpenApiRestCall_21625435
proc url_GetVoiceConnectorGroup_21626885(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_GetVoiceConnectorGroup_21626884(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_21626886 = path.getOrDefault("voiceConnectorGroupId")
  valid_21626886 = validateParameter(valid_21626886, JString, required = true,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "voiceConnectorGroupId", valid_21626886
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
  var valid_21626887 = header.getOrDefault("X-Amz-Date")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-Date", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Security-Token", valid_21626888
  var valid_21626889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626889 = validateParameter(valid_21626889, JString, required = false,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626889
  var valid_21626890 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "X-Amz-Algorithm", valid_21626890
  var valid_21626891 = header.getOrDefault("X-Amz-Signature")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "X-Amz-Signature", valid_21626891
  var valid_21626892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626892
  var valid_21626893 = header.getOrDefault("X-Amz-Credential")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "X-Amz-Credential", valid_21626893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626894: Call_GetVoiceConnectorGroup_21626883;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  let valid = call_21626894.validator(path, query, header, formData, body, _)
  let scheme = call_21626894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626894.makeUrl(scheme.get, call_21626894.host, call_21626894.base,
                               call_21626894.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626894, uri, valid, _)

proc call*(call_21626895: Call_GetVoiceConnectorGroup_21626883;
          voiceConnectorGroupId: string): Recallable =
  ## getVoiceConnectorGroup
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_21626896 = newJObject()
  add(path_21626896, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_21626895.call(path_21626896, nil, nil, nil, nil)

var getVoiceConnectorGroup* = Call_GetVoiceConnectorGroup_21626883(
    name: "getVoiceConnectorGroup", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_GetVoiceConnectorGroup_21626884, base: "/",
    makeUrl: url_GetVoiceConnectorGroup_21626885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorGroup_21626913 = ref object of OpenApiRestCall_21625435
proc url_DeleteVoiceConnectorGroup_21626915(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorGroup_21626914(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_21626916 = path.getOrDefault("voiceConnectorGroupId")
  valid_21626916 = validateParameter(valid_21626916, JString, required = true,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "voiceConnectorGroupId", valid_21626916
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
  var valid_21626917 = header.getOrDefault("X-Amz-Date")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Date", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Security-Token", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Algorithm", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Signature")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Signature", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-Credential")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-Credential", valid_21626923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626924: Call_DeleteVoiceConnectorGroup_21626913;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  let valid = call_21626924.validator(path, query, header, formData, body, _)
  let scheme = call_21626924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626924.makeUrl(scheme.get, call_21626924.host, call_21626924.base,
                               call_21626924.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626924, uri, valid, _)

proc call*(call_21626925: Call_DeleteVoiceConnectorGroup_21626913;
          voiceConnectorGroupId: string): Recallable =
  ## deleteVoiceConnectorGroup
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_21626926 = newJObject()
  add(path_21626926, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_21626925.call(path_21626926, nil, nil, nil, nil)

var deleteVoiceConnectorGroup* = Call_DeleteVoiceConnectorGroup_21626913(
    name: "deleteVoiceConnectorGroup", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_DeleteVoiceConnectorGroup_21626914, base: "/",
    makeUrl: url_DeleteVoiceConnectorGroup_21626915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_21626941 = ref object of OpenApiRestCall_21625435
proc url_PutVoiceConnectorOrigination_21626943(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorOrigination_21626942(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626944 = path.getOrDefault("voiceConnectorId")
  valid_21626944 = validateParameter(valid_21626944, JString, required = true,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "voiceConnectorId", valid_21626944
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
  var valid_21626945 = header.getOrDefault("X-Amz-Date")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Date", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Security-Token", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Algorithm", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Signature")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Signature", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Credential")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Credential", valid_21626951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626953: Call_PutVoiceConnectorOrigination_21626941;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21626953.validator(path, query, header, formData, body, _)
  let scheme = call_21626953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626953.makeUrl(scheme.get, call_21626953.host, call_21626953.base,
                               call_21626953.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626953, uri, valid, _)

proc call*(call_21626954: Call_PutVoiceConnectorOrigination_21626941;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_21626955 = newJObject()
  var body_21626956 = newJObject()
  add(path_21626955, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_21626956 = body
  result = call_21626954.call(path_21626955, nil, nil, nil, body_21626956)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_21626941(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_21626942, base: "/",
    makeUrl: url_PutVoiceConnectorOrigination_21626943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_21626927 = ref object of OpenApiRestCall_21625435
proc url_GetVoiceConnectorOrigination_21626929(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorOrigination_21626928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626930 = path.getOrDefault("voiceConnectorId")
  valid_21626930 = validateParameter(valid_21626930, JString, required = true,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "voiceConnectorId", valid_21626930
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
  var valid_21626931 = header.getOrDefault("X-Amz-Date")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Date", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Security-Token", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Algorithm", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Signature")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Signature", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Credential")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Credential", valid_21626937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626938: Call_GetVoiceConnectorOrigination_21626927;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21626938.validator(path, query, header, formData, body, _)
  let scheme = call_21626938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626938.makeUrl(scheme.get, call_21626938.host, call_21626938.base,
                               call_21626938.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626938, uri, valid, _)

proc call*(call_21626939: Call_GetVoiceConnectorOrigination_21626927;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21626940 = newJObject()
  add(path_21626940, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21626939.call(path_21626940, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_21626927(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_21626928, base: "/",
    makeUrl: url_GetVoiceConnectorOrigination_21626929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_21626957 = ref object of OpenApiRestCall_21625435
proc url_DeleteVoiceConnectorOrigination_21626959(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorOrigination_21626958(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626960 = path.getOrDefault("voiceConnectorId")
  valid_21626960 = validateParameter(valid_21626960, JString, required = true,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "voiceConnectorId", valid_21626960
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
  var valid_21626961 = header.getOrDefault("X-Amz-Date")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Date", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Security-Token", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-Algorithm", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Signature")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Signature", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Credential")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Credential", valid_21626967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626968: Call_DeleteVoiceConnectorOrigination_21626957;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21626968.validator(path, query, header, formData, body, _)
  let scheme = call_21626968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626968.makeUrl(scheme.get, call_21626968.host, call_21626968.base,
                               call_21626968.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626968, uri, valid, _)

proc call*(call_21626969: Call_DeleteVoiceConnectorOrigination_21626957;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21626970 = newJObject()
  add(path_21626970, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21626969.call(path_21626970, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_21626957(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_21626958, base: "/",
    makeUrl: url_DeleteVoiceConnectorOrigination_21626959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorStreamingConfiguration_21626985 = ref object of OpenApiRestCall_21625435
proc url_PutVoiceConnectorStreamingConfiguration_21626987(protocol: Scheme;
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

proc validate_PutVoiceConnectorStreamingConfiguration_21626986(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626988 = path.getOrDefault("voiceConnectorId")
  valid_21626988 = validateParameter(valid_21626988, JString, required = true,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "voiceConnectorId", valid_21626988
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
  var valid_21626989 = header.getOrDefault("X-Amz-Date")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-Date", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Security-Token", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Algorithm", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Signature")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Signature", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Credential")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Credential", valid_21626995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626997: Call_PutVoiceConnectorStreamingConfiguration_21626985;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_21626997.validator(path, query, header, formData, body, _)
  let scheme = call_21626997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626997.makeUrl(scheme.get, call_21626997.host, call_21626997.base,
                               call_21626997.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626997, uri, valid, _)

proc call*(call_21626998: Call_PutVoiceConnectorStreamingConfiguration_21626985;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorStreamingConfiguration
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_21626999 = newJObject()
  var body_21627000 = newJObject()
  add(path_21626999, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_21627000 = body
  result = call_21626998.call(path_21626999, nil, nil, nil, body_21627000)

var putVoiceConnectorStreamingConfiguration* = Call_PutVoiceConnectorStreamingConfiguration_21626985(
    name: "putVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_PutVoiceConnectorStreamingConfiguration_21626986,
    base: "/", makeUrl: url_PutVoiceConnectorStreamingConfiguration_21626987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorStreamingConfiguration_21626971 = ref object of OpenApiRestCall_21625435
proc url_GetVoiceConnectorStreamingConfiguration_21626973(protocol: Scheme;
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

proc validate_GetVoiceConnectorStreamingConfiguration_21626972(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626974 = path.getOrDefault("voiceConnectorId")
  valid_21626974 = validateParameter(valid_21626974, JString, required = true,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "voiceConnectorId", valid_21626974
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
  var valid_21626975 = header.getOrDefault("X-Amz-Date")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Date", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Security-Token", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Algorithm", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Signature")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Signature", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Credential")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Credential", valid_21626981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626982: Call_GetVoiceConnectorStreamingConfiguration_21626971;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_21626982.validator(path, query, header, formData, body, _)
  let scheme = call_21626982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626982.makeUrl(scheme.get, call_21626982.host, call_21626982.base,
                               call_21626982.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626982, uri, valid, _)

proc call*(call_21626983: Call_GetVoiceConnectorStreamingConfiguration_21626971;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorStreamingConfiguration
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21626984 = newJObject()
  add(path_21626984, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21626983.call(path_21626984, nil, nil, nil, nil)

var getVoiceConnectorStreamingConfiguration* = Call_GetVoiceConnectorStreamingConfiguration_21626971(
    name: "getVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_GetVoiceConnectorStreamingConfiguration_21626972,
    base: "/", makeUrl: url_GetVoiceConnectorStreamingConfiguration_21626973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorStreamingConfiguration_21627001 = ref object of OpenApiRestCall_21625435
proc url_DeleteVoiceConnectorStreamingConfiguration_21627003(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorStreamingConfiguration_21627002(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627004 = path.getOrDefault("voiceConnectorId")
  valid_21627004 = validateParameter(valid_21627004, JString, required = true,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "voiceConnectorId", valid_21627004
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
  var valid_21627005 = header.getOrDefault("X-Amz-Date")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-Date", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-Security-Token", valid_21627006
  var valid_21627007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Algorithm", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Signature")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Signature", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Credential")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Credential", valid_21627011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627012: Call_DeleteVoiceConnectorStreamingConfiguration_21627001;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627012.validator(path, query, header, formData, body, _)
  let scheme = call_21627012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627012.makeUrl(scheme.get, call_21627012.host, call_21627012.base,
                               call_21627012.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627012, uri, valid, _)

proc call*(call_21627013: Call_DeleteVoiceConnectorStreamingConfiguration_21627001;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorStreamingConfiguration
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21627014 = newJObject()
  add(path_21627014, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21627013.call(path_21627014, nil, nil, nil, nil)

var deleteVoiceConnectorStreamingConfiguration* = Call_DeleteVoiceConnectorStreamingConfiguration_21627001(
    name: "deleteVoiceConnectorStreamingConfiguration",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_DeleteVoiceConnectorStreamingConfiguration_21627002,
    base: "/", makeUrl: url_DeleteVoiceConnectorStreamingConfiguration_21627003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_21627029 = ref object of OpenApiRestCall_21625435
proc url_PutVoiceConnectorTermination_21627031(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorTermination_21627030(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627032 = path.getOrDefault("voiceConnectorId")
  valid_21627032 = validateParameter(valid_21627032, JString, required = true,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "voiceConnectorId", valid_21627032
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
  var valid_21627033 = header.getOrDefault("X-Amz-Date")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Date", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Security-Token", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Algorithm", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Signature")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Signature", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Credential")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Credential", valid_21627039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627041: Call_PutVoiceConnectorTermination_21627029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627041.validator(path, query, header, formData, body, _)
  let scheme = call_21627041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627041.makeUrl(scheme.get, call_21627041.host, call_21627041.base,
                               call_21627041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627041, uri, valid, _)

proc call*(call_21627042: Call_PutVoiceConnectorTermination_21627029;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_21627043 = newJObject()
  var body_21627044 = newJObject()
  add(path_21627043, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_21627044 = body
  result = call_21627042.call(path_21627043, nil, nil, nil, body_21627044)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_21627029(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_21627030, base: "/",
    makeUrl: url_PutVoiceConnectorTermination_21627031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_21627015 = ref object of OpenApiRestCall_21625435
proc url_GetVoiceConnectorTermination_21627017(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTermination_21627016(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627018 = path.getOrDefault("voiceConnectorId")
  valid_21627018 = validateParameter(valid_21627018, JString, required = true,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "voiceConnectorId", valid_21627018
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
  var valid_21627019 = header.getOrDefault("X-Amz-Date")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Date", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Security-Token", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Algorithm", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Signature")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Signature", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Credential")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Credential", valid_21627025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627026: Call_GetVoiceConnectorTermination_21627015;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627026.validator(path, query, header, formData, body, _)
  let scheme = call_21627026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627026.makeUrl(scheme.get, call_21627026.host, call_21627026.base,
                               call_21627026.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627026, uri, valid, _)

proc call*(call_21627027: Call_GetVoiceConnectorTermination_21627015;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21627028 = newJObject()
  add(path_21627028, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21627027.call(path_21627028, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_21627015(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_21627016, base: "/",
    makeUrl: url_GetVoiceConnectorTermination_21627017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_21627045 = ref object of OpenApiRestCall_21625435
proc url_DeleteVoiceConnectorTermination_21627047(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorTermination_21627046(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627048 = path.getOrDefault("voiceConnectorId")
  valid_21627048 = validateParameter(valid_21627048, JString, required = true,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "voiceConnectorId", valid_21627048
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
  var valid_21627049 = header.getOrDefault("X-Amz-Date")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "X-Amz-Date", valid_21627049
  var valid_21627050 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-Security-Token", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-Algorithm", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Signature")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Signature", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Credential")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Credential", valid_21627055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627056: Call_DeleteVoiceConnectorTermination_21627045;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627056.validator(path, query, header, formData, body, _)
  let scheme = call_21627056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627056.makeUrl(scheme.get, call_21627056.host, call_21627056.base,
                               call_21627056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627056, uri, valid, _)

proc call*(call_21627057: Call_DeleteVoiceConnectorTermination_21627045;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21627058 = newJObject()
  add(path_21627058, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21627057.call(path_21627058, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_21627045(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_21627046, base: "/",
    makeUrl: url_DeleteVoiceConnectorTermination_21627047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_21627059 = ref object of OpenApiRestCall_21625435
proc url_DeleteVoiceConnectorTerminationCredentials_21627061(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorTerminationCredentials_21627060(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627062 = path.getOrDefault("voiceConnectorId")
  valid_21627062 = validateParameter(valid_21627062, JString, required = true,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "voiceConnectorId", valid_21627062
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627063 = query.getOrDefault("operation")
  valid_21627063 = validateParameter(valid_21627063, JString, required = true,
                                   default = newJString("delete"))
  if valid_21627063 != nil:
    section.add "operation", valid_21627063
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
  var valid_21627064 = header.getOrDefault("X-Amz-Date")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-Date", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Security-Token", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Algorithm", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Signature")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Signature", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Credential")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Credential", valid_21627070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627072: Call_DeleteVoiceConnectorTerminationCredentials_21627059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_21627072.validator(path, query, header, formData, body, _)
  let scheme = call_21627072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627072.makeUrl(scheme.get, call_21627072.host, call_21627072.base,
                               call_21627072.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627072, uri, valid, _)

proc call*(call_21627073: Call_DeleteVoiceConnectorTerminationCredentials_21627059;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21627074 = newJObject()
  var query_21627075 = newJObject()
  var body_21627076 = newJObject()
  add(path_21627074, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_21627075, "operation", newJString(operation))
  if body != nil:
    body_21627076 = body
  result = call_21627073.call(path_21627074, query_21627075, nil, nil, body_21627076)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_21627059(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_21627060,
    base: "/", makeUrl: url_DeleteVoiceConnectorTerminationCredentials_21627061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_21627077 = ref object of OpenApiRestCall_21625435
proc url_DisassociatePhoneNumberFromUser_21627079(protocol: Scheme; host: string;
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

proc validate_DisassociatePhoneNumberFromUser_21627078(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627080 = path.getOrDefault("accountId")
  valid_21627080 = validateParameter(valid_21627080, JString, required = true,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "accountId", valid_21627080
  var valid_21627081 = path.getOrDefault("userId")
  valid_21627081 = validateParameter(valid_21627081, JString, required = true,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "userId", valid_21627081
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627082 = query.getOrDefault("operation")
  valid_21627082 = validateParameter(valid_21627082, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_21627082 != nil:
    section.add "operation", valid_21627082
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
  var valid_21627083 = header.getOrDefault("X-Amz-Date")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Date", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Security-Token", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Algorithm", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Signature")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Signature", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Credential")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Credential", valid_21627089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627090: Call_DisassociatePhoneNumberFromUser_21627077;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_21627090.validator(path, query, header, formData, body, _)
  let scheme = call_21627090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627090.makeUrl(scheme.get, call_21627090.host, call_21627090.base,
                               call_21627090.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627090, uri, valid, _)

proc call*(call_21627091: Call_DisassociatePhoneNumberFromUser_21627077;
          accountId: string; userId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_21627092 = newJObject()
  var query_21627093 = newJObject()
  add(path_21627092, "accountId", newJString(accountId))
  add(query_21627093, "operation", newJString(operation))
  add(path_21627092, "userId", newJString(userId))
  result = call_21627091.call(path_21627092, query_21627093, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_21627077(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_21627078, base: "/",
    makeUrl: url_DisassociatePhoneNumberFromUser_21627079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_21627094 = ref object of OpenApiRestCall_21625435
proc url_DisassociatePhoneNumbersFromVoiceConnector_21627096(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnector_21627095(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627097 = path.getOrDefault("voiceConnectorId")
  valid_21627097 = validateParameter(valid_21627097, JString, required = true,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "voiceConnectorId", valid_21627097
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627098 = query.getOrDefault("operation")
  valid_21627098 = validateParameter(valid_21627098, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_21627098 != nil:
    section.add "operation", valid_21627098
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
  var valid_21627099 = header.getOrDefault("X-Amz-Date")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-Date", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Security-Token", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Algorithm", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Signature")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Signature", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Credential")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Credential", valid_21627105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627107: Call_DisassociatePhoneNumbersFromVoiceConnector_21627094;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627107.validator(path, query, header, formData, body, _)
  let scheme = call_21627107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627107.makeUrl(scheme.get, call_21627107.host, call_21627107.base,
                               call_21627107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627107, uri, valid, _)

proc call*(call_21627108: Call_DisassociatePhoneNumbersFromVoiceConnector_21627094;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21627109 = newJObject()
  var query_21627110 = newJObject()
  var body_21627111 = newJObject()
  add(path_21627109, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_21627110, "operation", newJString(operation))
  if body != nil:
    body_21627111 = body
  result = call_21627108.call(path_21627109, query_21627110, nil, nil, body_21627111)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_21627094(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_21627095,
    base: "/", makeUrl: url_DisassociatePhoneNumbersFromVoiceConnector_21627096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627112 = ref object of OpenApiRestCall_21625435
proc url_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627114(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
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

proc validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627113(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorGroupId: JString (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `voiceConnectorGroupId` field"
  var valid_21627115 = path.getOrDefault("voiceConnectorGroupId")
  valid_21627115 = validateParameter(valid_21627115, JString, required = true,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "voiceConnectorGroupId", valid_21627115
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627116 = query.getOrDefault("operation")
  valid_21627116 = validateParameter(valid_21627116, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_21627116 != nil:
    section.add "operation", valid_21627116
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
  var valid_21627117 = header.getOrDefault("X-Amz-Date")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Date", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Security-Token", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Algorithm", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-Signature")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Signature", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627122
  var valid_21627123 = header.getOrDefault("X-Amz-Credential")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Credential", valid_21627123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627125: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627112;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_21627125.validator(path, query, header, formData, body, _)
  let scheme = call_21627125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627125.makeUrl(scheme.get, call_21627125.host, call_21627125.base,
                               call_21627125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627125, uri, valid, _)

proc call*(call_21627126: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627112;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnectorGroup
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21627127 = newJObject()
  var query_21627128 = newJObject()
  var body_21627129 = newJObject()
  add(path_21627127, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_21627128, "operation", newJString(operation))
  if body != nil:
    body_21627129 = body
  result = call_21627126.call(path_21627127, query_21627128, nil, nil, body_21627129)

var disassociatePhoneNumbersFromVoiceConnectorGroup* = Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627112(
    name: "disassociatePhoneNumbersFromVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627113,
    base: "/", makeUrl: url_DisassociatePhoneNumbersFromVoiceConnectorGroup_21627114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSigninDelegateGroupsFromAccount_21627130 = ref object of OpenApiRestCall_21625435
proc url_DisassociateSigninDelegateGroupsFromAccount_21627132(protocol: Scheme;
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

proc validate_DisassociateSigninDelegateGroupsFromAccount_21627131(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21627133 = path.getOrDefault("accountId")
  valid_21627133 = validateParameter(valid_21627133, JString, required = true,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "accountId", valid_21627133
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627134 = query.getOrDefault("operation")
  valid_21627134 = validateParameter(valid_21627134, JString, required = true, default = newJString(
      "disassociate-signin-delegate-groups"))
  if valid_21627134 != nil:
    section.add "operation", valid_21627134
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
  var valid_21627135 = header.getOrDefault("X-Amz-Date")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Date", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Security-Token", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Algorithm", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Signature")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Signature", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Credential")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Credential", valid_21627141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627143: Call_DisassociateSigninDelegateGroupsFromAccount_21627130;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ## 
  let valid = call_21627143.validator(path, query, header, formData, body, _)
  let scheme = call_21627143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627143.makeUrl(scheme.get, call_21627143.host, call_21627143.base,
                               call_21627143.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627143, uri, valid, _)

proc call*(call_21627144: Call_DisassociateSigninDelegateGroupsFromAccount_21627130;
          accountId: string; body: JsonNode;
          operation: string = "disassociate-signin-delegate-groups"): Recallable =
  ## disassociateSigninDelegateGroupsFromAccount
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21627145 = newJObject()
  var query_21627146 = newJObject()
  var body_21627147 = newJObject()
  add(path_21627145, "accountId", newJString(accountId))
  add(query_21627146, "operation", newJString(operation))
  if body != nil:
    body_21627147 = body
  result = call_21627144.call(path_21627145, query_21627146, nil, nil, body_21627147)

var disassociateSigninDelegateGroupsFromAccount* = Call_DisassociateSigninDelegateGroupsFromAccount_21627130(
    name: "disassociateSigninDelegateGroupsFromAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts/{accountId}#operation=disassociate-signin-delegate-groups",
    validator: validate_DisassociateSigninDelegateGroupsFromAccount_21627131,
    base: "/", makeUrl: url_DisassociateSigninDelegateGroupsFromAccount_21627132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_21627162 = ref object of OpenApiRestCall_21625435
proc url_UpdateAccountSettings_21627164(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_UpdateAccountSettings_21627163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21627165 = path.getOrDefault("accountId")
  valid_21627165 = validateParameter(valid_21627165, JString, required = true,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "accountId", valid_21627165
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
  var valid_21627166 = header.getOrDefault("X-Amz-Date")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-Date", valid_21627166
  var valid_21627167 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "X-Amz-Security-Token", valid_21627167
  var valid_21627168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Algorithm", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Signature")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Signature", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Credential")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Credential", valid_21627172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627174: Call_UpdateAccountSettings_21627162;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_21627174.validator(path, query, header, formData, body, _)
  let scheme = call_21627174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627174.makeUrl(scheme.get, call_21627174.host, call_21627174.base,
                               call_21627174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627174, uri, valid, _)

proc call*(call_21627175: Call_UpdateAccountSettings_21627162; accountId: string;
          body: JsonNode): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_21627176 = newJObject()
  var body_21627177 = newJObject()
  add(path_21627176, "accountId", newJString(accountId))
  if body != nil:
    body_21627177 = body
  result = call_21627175.call(path_21627176, nil, nil, nil, body_21627177)

var updateAccountSettings* = Call_UpdateAccountSettings_21627162(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_21627163, base: "/",
    makeUrl: url_UpdateAccountSettings_21627164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_21627148 = ref object of OpenApiRestCall_21625435
proc url_GetAccountSettings_21627150(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_21627149(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21627151 = path.getOrDefault("accountId")
  valid_21627151 = validateParameter(valid_21627151, JString, required = true,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "accountId", valid_21627151
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
  var valid_21627152 = header.getOrDefault("X-Amz-Date")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Date", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Security-Token", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Algorithm", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Signature")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Signature", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-Credential")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Credential", valid_21627158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627159: Call_GetAccountSettings_21627148; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_21627159.validator(path, query, header, formData, body, _)
  let scheme = call_21627159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627159.makeUrl(scheme.get, call_21627159.host, call_21627159.base,
                               call_21627159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627159, uri, valid, _)

proc call*(call_21627160: Call_GetAccountSettings_21627148; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_21627161 = newJObject()
  add(path_21627161, "accountId", newJString(accountId))
  result = call_21627160.call(path_21627161, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_21627148(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_21627149, base: "/",
    makeUrl: url_GetAccountSettings_21627150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_21627193 = ref object of OpenApiRestCall_21625435
proc url_UpdateBot_21627195(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "botId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBot_21627194(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627196 = path.getOrDefault("accountId")
  valid_21627196 = validateParameter(valid_21627196, JString, required = true,
                                   default = nil)
  if valid_21627196 != nil:
    section.add "accountId", valid_21627196
  var valid_21627197 = path.getOrDefault("botId")
  valid_21627197 = validateParameter(valid_21627197, JString, required = true,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "botId", valid_21627197
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
  var valid_21627198 = header.getOrDefault("X-Amz-Date")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "X-Amz-Date", valid_21627198
  var valid_21627199 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627199 = validateParameter(valid_21627199, JString, required = false,
                                   default = nil)
  if valid_21627199 != nil:
    section.add "X-Amz-Security-Token", valid_21627199
  var valid_21627200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627200 = validateParameter(valid_21627200, JString, required = false,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627200
  var valid_21627201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627201 = validateParameter(valid_21627201, JString, required = false,
                                   default = nil)
  if valid_21627201 != nil:
    section.add "X-Amz-Algorithm", valid_21627201
  var valid_21627202 = header.getOrDefault("X-Amz-Signature")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Signature", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Credential")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Credential", valid_21627204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627206: Call_UpdateBot_21627193; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_21627206.validator(path, query, header, formData, body, _)
  let scheme = call_21627206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627206.makeUrl(scheme.get, call_21627206.host, call_21627206.base,
                               call_21627206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627206, uri, valid, _)

proc call*(call_21627207: Call_UpdateBot_21627193; accountId: string; botId: string;
          body: JsonNode): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_21627208 = newJObject()
  var body_21627209 = newJObject()
  add(path_21627208, "accountId", newJString(accountId))
  add(path_21627208, "botId", newJString(botId))
  if body != nil:
    body_21627209 = body
  result = call_21627207.call(path_21627208, nil, nil, nil, body_21627209)

var updateBot* = Call_UpdateBot_21627193(name: "updateBot",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                      validator: validate_UpdateBot_21627194,
                                      base: "/", makeUrl: url_UpdateBot_21627195,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_21627178 = ref object of OpenApiRestCall_21625435
proc url_GetBot_21627180(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_21627179(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627181 = path.getOrDefault("accountId")
  valid_21627181 = validateParameter(valid_21627181, JString, required = true,
                                   default = nil)
  if valid_21627181 != nil:
    section.add "accountId", valid_21627181
  var valid_21627182 = path.getOrDefault("botId")
  valid_21627182 = validateParameter(valid_21627182, JString, required = true,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "botId", valid_21627182
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
  var valid_21627183 = header.getOrDefault("X-Amz-Date")
  valid_21627183 = validateParameter(valid_21627183, JString, required = false,
                                   default = nil)
  if valid_21627183 != nil:
    section.add "X-Amz-Date", valid_21627183
  var valid_21627184 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627184 = validateParameter(valid_21627184, JString, required = false,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "X-Amz-Security-Token", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Algorithm", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-Signature")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Signature", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Credential")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Credential", valid_21627189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627190: Call_GetBot_21627178; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_21627190.validator(path, query, header, formData, body, _)
  let scheme = call_21627190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627190.makeUrl(scheme.get, call_21627190.host, call_21627190.base,
                               call_21627190.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627190, uri, valid, _)

proc call*(call_21627191: Call_GetBot_21627178; accountId: string; botId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_21627192 = newJObject()
  add(path_21627192, "accountId", newJString(accountId))
  add(path_21627192, "botId", newJString(botId))
  result = call_21627191.call(path_21627192, nil, nil, nil, nil)

var getBot* = Call_GetBot_21627178(name: "getBot", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/bots/{botId}",
                                validator: validate_GetBot_21627179, base: "/",
                                makeUrl: url_GetBot_21627180,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_21627222 = ref object of OpenApiRestCall_21625435
proc url_UpdateGlobalSettings_21627224(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGlobalSettings_21627223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627225 = header.getOrDefault("X-Amz-Date")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Date", valid_21627225
  var valid_21627226 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627226 = validateParameter(valid_21627226, JString, required = false,
                                   default = nil)
  if valid_21627226 != nil:
    section.add "X-Amz-Security-Token", valid_21627226
  var valid_21627227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627227
  var valid_21627228 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627228 = validateParameter(valid_21627228, JString, required = false,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "X-Amz-Algorithm", valid_21627228
  var valid_21627229 = header.getOrDefault("X-Amz-Signature")
  valid_21627229 = validateParameter(valid_21627229, JString, required = false,
                                   default = nil)
  if valid_21627229 != nil:
    section.add "X-Amz-Signature", valid_21627229
  var valid_21627230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627230 = validateParameter(valid_21627230, JString, required = false,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627230
  var valid_21627231 = header.getOrDefault("X-Amz-Credential")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-Credential", valid_21627231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627233: Call_UpdateGlobalSettings_21627222; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_21627233.validator(path, query, header, formData, body, _)
  let scheme = call_21627233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627233.makeUrl(scheme.get, call_21627233.host, call_21627233.base,
                               call_21627233.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627233, uri, valid, _)

proc call*(call_21627234: Call_UpdateGlobalSettings_21627222; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_21627235 = newJObject()
  if body != nil:
    body_21627235 = body
  result = call_21627234.call(nil, nil, nil, nil, body_21627235)

var updateGlobalSettings* = Call_UpdateGlobalSettings_21627222(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_21627223, base: "/",
    makeUrl: url_UpdateGlobalSettings_21627224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_21627210 = ref object of OpenApiRestCall_21625435
proc url_GetGlobalSettings_21627212(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGlobalSettings_21627211(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627213 = header.getOrDefault("X-Amz-Date")
  valid_21627213 = validateParameter(valid_21627213, JString, required = false,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "X-Amz-Date", valid_21627213
  var valid_21627214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627214 = validateParameter(valid_21627214, JString, required = false,
                                   default = nil)
  if valid_21627214 != nil:
    section.add "X-Amz-Security-Token", valid_21627214
  var valid_21627215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627215 = validateParameter(valid_21627215, JString, required = false,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627215
  var valid_21627216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "X-Amz-Algorithm", valid_21627216
  var valid_21627217 = header.getOrDefault("X-Amz-Signature")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Signature", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Credential")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Credential", valid_21627219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627220: Call_GetGlobalSettings_21627210; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_21627220.validator(path, query, header, formData, body, _)
  let scheme = call_21627220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627220.makeUrl(scheme.get, call_21627220.host, call_21627220.base,
                               call_21627220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627220, uri, valid, _)

proc call*(call_21627221: Call_GetGlobalSettings_21627210): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_21627221.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_21627210(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_21627211, base: "/",
    makeUrl: url_GetGlobalSettings_21627212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_21627236 = ref object of OpenApiRestCall_21625435
proc url_GetPhoneNumberOrder_21627238(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberOrder_21627237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627239 = path.getOrDefault("phoneNumberOrderId")
  valid_21627239 = validateParameter(valid_21627239, JString, required = true,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "phoneNumberOrderId", valid_21627239
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
  var valid_21627240 = header.getOrDefault("X-Amz-Date")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Date", valid_21627240
  var valid_21627241 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-Security-Token", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627242
  var valid_21627243 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627243 = validateParameter(valid_21627243, JString, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "X-Amz-Algorithm", valid_21627243
  var valid_21627244 = header.getOrDefault("X-Amz-Signature")
  valid_21627244 = validateParameter(valid_21627244, JString, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "X-Amz-Signature", valid_21627244
  var valid_21627245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627245 = validateParameter(valid_21627245, JString, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627245
  var valid_21627246 = header.getOrDefault("X-Amz-Credential")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "X-Amz-Credential", valid_21627246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627247: Call_GetPhoneNumberOrder_21627236; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_21627247.validator(path, query, header, formData, body, _)
  let scheme = call_21627247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627247.makeUrl(scheme.get, call_21627247.host, call_21627247.base,
                               call_21627247.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627247, uri, valid, _)

proc call*(call_21627248: Call_GetPhoneNumberOrder_21627236;
          phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_21627249 = newJObject()
  add(path_21627249, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_21627248.call(path_21627249, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_21627236(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_21627237, base: "/",
    makeUrl: url_GetPhoneNumberOrder_21627238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumberSettings_21627262 = ref object of OpenApiRestCall_21625435
proc url_UpdatePhoneNumberSettings_21627264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePhoneNumberSettings_21627263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
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
  var valid_21627265 = header.getOrDefault("X-Amz-Date")
  valid_21627265 = validateParameter(valid_21627265, JString, required = false,
                                   default = nil)
  if valid_21627265 != nil:
    section.add "X-Amz-Date", valid_21627265
  var valid_21627266 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-Security-Token", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627267
  var valid_21627268 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "X-Amz-Algorithm", valid_21627268
  var valid_21627269 = header.getOrDefault("X-Amz-Signature")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "X-Amz-Signature", valid_21627269
  var valid_21627270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627270 = validateParameter(valid_21627270, JString, required = false,
                                   default = nil)
  if valid_21627270 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627270
  var valid_21627271 = header.getOrDefault("X-Amz-Credential")
  valid_21627271 = validateParameter(valid_21627271, JString, required = false,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "X-Amz-Credential", valid_21627271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627273: Call_UpdatePhoneNumberSettings_21627262;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ## 
  let valid = call_21627273.validator(path, query, header, formData, body, _)
  let scheme = call_21627273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627273.makeUrl(scheme.get, call_21627273.host, call_21627273.base,
                               call_21627273.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627273, uri, valid, _)

proc call*(call_21627274: Call_UpdatePhoneNumberSettings_21627262; body: JsonNode): Recallable =
  ## updatePhoneNumberSettings
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ##   body: JObject (required)
  var body_21627275 = newJObject()
  if body != nil:
    body_21627275 = body
  result = call_21627274.call(nil, nil, nil, nil, body_21627275)

var updatePhoneNumberSettings* = Call_UpdatePhoneNumberSettings_21627262(
    name: "updatePhoneNumberSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_UpdatePhoneNumberSettings_21627263, base: "/",
    makeUrl: url_UpdatePhoneNumberSettings_21627264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberSettings_21627250 = ref object of OpenApiRestCall_21625435
proc url_GetPhoneNumberSettings_21627252(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPhoneNumberSettings_21627251(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
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
  var valid_21627253 = header.getOrDefault("X-Amz-Date")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "X-Amz-Date", valid_21627253
  var valid_21627254 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "X-Amz-Security-Token", valid_21627254
  var valid_21627255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627255 = validateParameter(valid_21627255, JString, required = false,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627255
  var valid_21627256 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627256 = validateParameter(valid_21627256, JString, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "X-Amz-Algorithm", valid_21627256
  var valid_21627257 = header.getOrDefault("X-Amz-Signature")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-Signature", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-Credential")
  valid_21627259 = validateParameter(valid_21627259, JString, required = false,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "X-Amz-Credential", valid_21627259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627260: Call_GetPhoneNumberSettings_21627250;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  let valid = call_21627260.validator(path, query, header, formData, body, _)
  let scheme = call_21627260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627260.makeUrl(scheme.get, call_21627260.host, call_21627260.base,
                               call_21627260.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627260, uri, valid, _)

proc call*(call_21627261: Call_GetPhoneNumberSettings_21627250): Recallable =
  ## getPhoneNumberSettings
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  result = call_21627261.call(nil, nil, nil, nil, nil)

var getPhoneNumberSettings* = Call_GetPhoneNumberSettings_21627250(
    name: "getPhoneNumberSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_GetPhoneNumberSettings_21627251, base: "/",
    makeUrl: url_GetPhoneNumberSettings_21627252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_21627291 = ref object of OpenApiRestCall_21625435
proc url_UpdateUser_21627293(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "userId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_21627292(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627294 = path.getOrDefault("accountId")
  valid_21627294 = validateParameter(valid_21627294, JString, required = true,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "accountId", valid_21627294
  var valid_21627295 = path.getOrDefault("userId")
  valid_21627295 = validateParameter(valid_21627295, JString, required = true,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "userId", valid_21627295
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
  var valid_21627296 = header.getOrDefault("X-Amz-Date")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-Date", valid_21627296
  var valid_21627297 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "X-Amz-Security-Token", valid_21627297
  var valid_21627298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627298 = validateParameter(valid_21627298, JString, required = false,
                                   default = nil)
  if valid_21627298 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627298
  var valid_21627299 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627299 = validateParameter(valid_21627299, JString, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "X-Amz-Algorithm", valid_21627299
  var valid_21627300 = header.getOrDefault("X-Amz-Signature")
  valid_21627300 = validateParameter(valid_21627300, JString, required = false,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "X-Amz-Signature", valid_21627300
  var valid_21627301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627301 = validateParameter(valid_21627301, JString, required = false,
                                   default = nil)
  if valid_21627301 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627301
  var valid_21627302 = header.getOrDefault("X-Amz-Credential")
  valid_21627302 = validateParameter(valid_21627302, JString, required = false,
                                   default = nil)
  if valid_21627302 != nil:
    section.add "X-Amz-Credential", valid_21627302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627304: Call_UpdateUser_21627291; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_21627304.validator(path, query, header, formData, body, _)
  let scheme = call_21627304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627304.makeUrl(scheme.get, call_21627304.host, call_21627304.base,
                               call_21627304.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627304, uri, valid, _)

proc call*(call_21627305: Call_UpdateUser_21627291; accountId: string;
          body: JsonNode; userId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_21627306 = newJObject()
  var body_21627307 = newJObject()
  add(path_21627306, "accountId", newJString(accountId))
  if body != nil:
    body_21627307 = body
  add(path_21627306, "userId", newJString(userId))
  result = call_21627305.call(path_21627306, nil, nil, nil, body_21627307)

var updateUser* = Call_UpdateUser_21627291(name: "updateUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                        validator: validate_UpdateUser_21627292,
                                        base: "/", makeUrl: url_UpdateUser_21627293,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_21627276 = ref object of OpenApiRestCall_21625435
proc url_GetUser_21627278(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_21627277(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627279 = path.getOrDefault("accountId")
  valid_21627279 = validateParameter(valid_21627279, JString, required = true,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "accountId", valid_21627279
  var valid_21627280 = path.getOrDefault("userId")
  valid_21627280 = validateParameter(valid_21627280, JString, required = true,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "userId", valid_21627280
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
  var valid_21627281 = header.getOrDefault("X-Amz-Date")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-Date", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Security-Token", valid_21627282
  var valid_21627283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627283 = validateParameter(valid_21627283, JString, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627283
  var valid_21627284 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "X-Amz-Algorithm", valid_21627284
  var valid_21627285 = header.getOrDefault("X-Amz-Signature")
  valid_21627285 = validateParameter(valid_21627285, JString, required = false,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "X-Amz-Signature", valid_21627285
  var valid_21627286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627286 = validateParameter(valid_21627286, JString, required = false,
                                   default = nil)
  if valid_21627286 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627286
  var valid_21627287 = header.getOrDefault("X-Amz-Credential")
  valid_21627287 = validateParameter(valid_21627287, JString, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "X-Amz-Credential", valid_21627287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627288: Call_GetUser_21627276; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_21627288.validator(path, query, header, formData, body, _)
  let scheme = call_21627288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627288.makeUrl(scheme.get, call_21627288.host, call_21627288.base,
                               call_21627288.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627288, uri, valid, _)

proc call*(call_21627289: Call_GetUser_21627276; accountId: string; userId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_21627290 = newJObject()
  add(path_21627290, "accountId", newJString(accountId))
  add(path_21627290, "userId", newJString(userId))
  result = call_21627289.call(path_21627290, nil, nil, nil, nil)

var getUser* = Call_GetUser_21627276(name: "getUser", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                  validator: validate_GetUser_21627277, base: "/",
                                  makeUrl: url_GetUser_21627278,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_21627323 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserSettings_21627325(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserSettings_21627324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627326 = path.getOrDefault("accountId")
  valid_21627326 = validateParameter(valid_21627326, JString, required = true,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "accountId", valid_21627326
  var valid_21627327 = path.getOrDefault("userId")
  valid_21627327 = validateParameter(valid_21627327, JString, required = true,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "userId", valid_21627327
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
  var valid_21627328 = header.getOrDefault("X-Amz-Date")
  valid_21627328 = validateParameter(valid_21627328, JString, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "X-Amz-Date", valid_21627328
  var valid_21627329 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "X-Amz-Security-Token", valid_21627329
  var valid_21627330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627330 = validateParameter(valid_21627330, JString, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627330
  var valid_21627331 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627331 = validateParameter(valid_21627331, JString, required = false,
                                   default = nil)
  if valid_21627331 != nil:
    section.add "X-Amz-Algorithm", valid_21627331
  var valid_21627332 = header.getOrDefault("X-Amz-Signature")
  valid_21627332 = validateParameter(valid_21627332, JString, required = false,
                                   default = nil)
  if valid_21627332 != nil:
    section.add "X-Amz-Signature", valid_21627332
  var valid_21627333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627333 = validateParameter(valid_21627333, JString, required = false,
                                   default = nil)
  if valid_21627333 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627333
  var valid_21627334 = header.getOrDefault("X-Amz-Credential")
  valid_21627334 = validateParameter(valid_21627334, JString, required = false,
                                   default = nil)
  if valid_21627334 != nil:
    section.add "X-Amz-Credential", valid_21627334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627336: Call_UpdateUserSettings_21627323; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_21627336.validator(path, query, header, formData, body, _)
  let scheme = call_21627336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627336.makeUrl(scheme.get, call_21627336.host, call_21627336.base,
                               call_21627336.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627336, uri, valid, _)

proc call*(call_21627337: Call_UpdateUserSettings_21627323; accountId: string;
          body: JsonNode; userId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_21627338 = newJObject()
  var body_21627339 = newJObject()
  add(path_21627338, "accountId", newJString(accountId))
  if body != nil:
    body_21627339 = body
  add(path_21627338, "userId", newJString(userId))
  result = call_21627337.call(path_21627338, nil, nil, nil, body_21627339)

var updateUserSettings* = Call_UpdateUserSettings_21627323(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_21627324, base: "/",
    makeUrl: url_UpdateUserSettings_21627325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_21627308 = ref object of OpenApiRestCall_21625435
proc url_GetUserSettings_21627310(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserSettings_21627309(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627311 = path.getOrDefault("accountId")
  valid_21627311 = validateParameter(valid_21627311, JString, required = true,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "accountId", valid_21627311
  var valid_21627312 = path.getOrDefault("userId")
  valid_21627312 = validateParameter(valid_21627312, JString, required = true,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "userId", valid_21627312
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
  var valid_21627313 = header.getOrDefault("X-Amz-Date")
  valid_21627313 = validateParameter(valid_21627313, JString, required = false,
                                   default = nil)
  if valid_21627313 != nil:
    section.add "X-Amz-Date", valid_21627313
  var valid_21627314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627314 = validateParameter(valid_21627314, JString, required = false,
                                   default = nil)
  if valid_21627314 != nil:
    section.add "X-Amz-Security-Token", valid_21627314
  var valid_21627315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627315 = validateParameter(valid_21627315, JString, required = false,
                                   default = nil)
  if valid_21627315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627315
  var valid_21627316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627316 = validateParameter(valid_21627316, JString, required = false,
                                   default = nil)
  if valid_21627316 != nil:
    section.add "X-Amz-Algorithm", valid_21627316
  var valid_21627317 = header.getOrDefault("X-Amz-Signature")
  valid_21627317 = validateParameter(valid_21627317, JString, required = false,
                                   default = nil)
  if valid_21627317 != nil:
    section.add "X-Amz-Signature", valid_21627317
  var valid_21627318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627318 = validateParameter(valid_21627318, JString, required = false,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627318
  var valid_21627319 = header.getOrDefault("X-Amz-Credential")
  valid_21627319 = validateParameter(valid_21627319, JString, required = false,
                                   default = nil)
  if valid_21627319 != nil:
    section.add "X-Amz-Credential", valid_21627319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627320: Call_GetUserSettings_21627308; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_21627320.validator(path, query, header, formData, body, _)
  let scheme = call_21627320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627320.makeUrl(scheme.get, call_21627320.host, call_21627320.base,
                               call_21627320.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627320, uri, valid, _)

proc call*(call_21627321: Call_GetUserSettings_21627308; accountId: string;
          userId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_21627322 = newJObject()
  add(path_21627322, "accountId", newJString(accountId))
  add(path_21627322, "userId", newJString(userId))
  result = call_21627321.call(path_21627322, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_21627308(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_21627309, base: "/",
    makeUrl: url_GetUserSettings_21627310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorLoggingConfiguration_21627354 = ref object of OpenApiRestCall_21625435
proc url_PutVoiceConnectorLoggingConfiguration_21627356(protocol: Scheme;
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

proc validate_PutVoiceConnectorLoggingConfiguration_21627355(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627357 = path.getOrDefault("voiceConnectorId")
  valid_21627357 = validateParameter(valid_21627357, JString, required = true,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "voiceConnectorId", valid_21627357
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
  var valid_21627358 = header.getOrDefault("X-Amz-Date")
  valid_21627358 = validateParameter(valid_21627358, JString, required = false,
                                   default = nil)
  if valid_21627358 != nil:
    section.add "X-Amz-Date", valid_21627358
  var valid_21627359 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627359 = validateParameter(valid_21627359, JString, required = false,
                                   default = nil)
  if valid_21627359 != nil:
    section.add "X-Amz-Security-Token", valid_21627359
  var valid_21627360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627360 = validateParameter(valid_21627360, JString, required = false,
                                   default = nil)
  if valid_21627360 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627360
  var valid_21627361 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627361 = validateParameter(valid_21627361, JString, required = false,
                                   default = nil)
  if valid_21627361 != nil:
    section.add "X-Amz-Algorithm", valid_21627361
  var valid_21627362 = header.getOrDefault("X-Amz-Signature")
  valid_21627362 = validateParameter(valid_21627362, JString, required = false,
                                   default = nil)
  if valid_21627362 != nil:
    section.add "X-Amz-Signature", valid_21627362
  var valid_21627363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627363 = validateParameter(valid_21627363, JString, required = false,
                                   default = nil)
  if valid_21627363 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627363
  var valid_21627364 = header.getOrDefault("X-Amz-Credential")
  valid_21627364 = validateParameter(valid_21627364, JString, required = false,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "X-Amz-Credential", valid_21627364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627366: Call_PutVoiceConnectorLoggingConfiguration_21627354;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_21627366.validator(path, query, header, formData, body, _)
  let scheme = call_21627366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627366.makeUrl(scheme.get, call_21627366.host, call_21627366.base,
                               call_21627366.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627366, uri, valid, _)

proc call*(call_21627367: Call_PutVoiceConnectorLoggingConfiguration_21627354;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorLoggingConfiguration
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_21627368 = newJObject()
  var body_21627369 = newJObject()
  add(path_21627368, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_21627369 = body
  result = call_21627367.call(path_21627368, nil, nil, nil, body_21627369)

var putVoiceConnectorLoggingConfiguration* = Call_PutVoiceConnectorLoggingConfiguration_21627354(
    name: "putVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_PutVoiceConnectorLoggingConfiguration_21627355, base: "/",
    makeUrl: url_PutVoiceConnectorLoggingConfiguration_21627356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorLoggingConfiguration_21627340 = ref object of OpenApiRestCall_21625435
proc url_GetVoiceConnectorLoggingConfiguration_21627342(protocol: Scheme;
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

proc validate_GetVoiceConnectorLoggingConfiguration_21627341(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627343 = path.getOrDefault("voiceConnectorId")
  valid_21627343 = validateParameter(valid_21627343, JString, required = true,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "voiceConnectorId", valid_21627343
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
  var valid_21627344 = header.getOrDefault("X-Amz-Date")
  valid_21627344 = validateParameter(valid_21627344, JString, required = false,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "X-Amz-Date", valid_21627344
  var valid_21627345 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627345 = validateParameter(valid_21627345, JString, required = false,
                                   default = nil)
  if valid_21627345 != nil:
    section.add "X-Amz-Security-Token", valid_21627345
  var valid_21627346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627346
  var valid_21627347 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627347 = validateParameter(valid_21627347, JString, required = false,
                                   default = nil)
  if valid_21627347 != nil:
    section.add "X-Amz-Algorithm", valid_21627347
  var valid_21627348 = header.getOrDefault("X-Amz-Signature")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "X-Amz-Signature", valid_21627348
  var valid_21627349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Credential")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Credential", valid_21627350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627351: Call_GetVoiceConnectorLoggingConfiguration_21627340;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_21627351.validator(path, query, header, formData, body, _)
  let scheme = call_21627351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627351.makeUrl(scheme.get, call_21627351.host, call_21627351.base,
                               call_21627351.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627351, uri, valid, _)

proc call*(call_21627352: Call_GetVoiceConnectorLoggingConfiguration_21627340;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorLoggingConfiguration
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21627353 = newJObject()
  add(path_21627353, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21627352.call(path_21627353, nil, nil, nil, nil)

var getVoiceConnectorLoggingConfiguration* = Call_GetVoiceConnectorLoggingConfiguration_21627340(
    name: "getVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_GetVoiceConnectorLoggingConfiguration_21627341, base: "/",
    makeUrl: url_GetVoiceConnectorLoggingConfiguration_21627342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_21627370 = ref object of OpenApiRestCall_21625435
proc url_GetVoiceConnectorTerminationHealth_21627372(protocol: Scheme;
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
               (kind: ConstantSegment, value: "/termination/health")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetVoiceConnectorTerminationHealth_21627371(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627373 = path.getOrDefault("voiceConnectorId")
  valid_21627373 = validateParameter(valid_21627373, JString, required = true,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "voiceConnectorId", valid_21627373
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
  var valid_21627374 = header.getOrDefault("X-Amz-Date")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "X-Amz-Date", valid_21627374
  var valid_21627375 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "X-Amz-Security-Token", valid_21627375
  var valid_21627376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627376 = validateParameter(valid_21627376, JString, required = false,
                                   default = nil)
  if valid_21627376 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627376
  var valid_21627377 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627377 = validateParameter(valid_21627377, JString, required = false,
                                   default = nil)
  if valid_21627377 != nil:
    section.add "X-Amz-Algorithm", valid_21627377
  var valid_21627378 = header.getOrDefault("X-Amz-Signature")
  valid_21627378 = validateParameter(valid_21627378, JString, required = false,
                                   default = nil)
  if valid_21627378 != nil:
    section.add "X-Amz-Signature", valid_21627378
  var valid_21627379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627379 = validateParameter(valid_21627379, JString, required = false,
                                   default = nil)
  if valid_21627379 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627379
  var valid_21627380 = header.getOrDefault("X-Amz-Credential")
  valid_21627380 = validateParameter(valid_21627380, JString, required = false,
                                   default = nil)
  if valid_21627380 != nil:
    section.add "X-Amz-Credential", valid_21627380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627381: Call_GetVoiceConnectorTerminationHealth_21627370;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627381.validator(path, query, header, formData, body, _)
  let scheme = call_21627381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627381.makeUrl(scheme.get, call_21627381.host, call_21627381.base,
                               call_21627381.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627381, uri, valid, _)

proc call*(call_21627382: Call_GetVoiceConnectorTerminationHealth_21627370;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21627383 = newJObject()
  add(path_21627383, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21627382.call(path_21627383, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_21627370(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_21627371, base: "/",
    makeUrl: url_GetVoiceConnectorTerminationHealth_21627372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_21627384 = ref object of OpenApiRestCall_21625435
proc url_InviteUsers_21627386(protocol: Scheme; host: string; base: string;
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

proc validate_InviteUsers_21627385(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The Amazon Chime account ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_21627387 = path.getOrDefault("accountId")
  valid_21627387 = validateParameter(valid_21627387, JString, required = true,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "accountId", valid_21627387
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627388 = query.getOrDefault("operation")
  valid_21627388 = validateParameter(valid_21627388, JString, required = true,
                                   default = newJString("add"))
  if valid_21627388 != nil:
    section.add "operation", valid_21627388
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
  var valid_21627389 = header.getOrDefault("X-Amz-Date")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-Date", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Security-Token", valid_21627390
  var valid_21627391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627391 = validateParameter(valid_21627391, JString, required = false,
                                   default = nil)
  if valid_21627391 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627391
  var valid_21627392 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627392 = validateParameter(valid_21627392, JString, required = false,
                                   default = nil)
  if valid_21627392 != nil:
    section.add "X-Amz-Algorithm", valid_21627392
  var valid_21627393 = header.getOrDefault("X-Amz-Signature")
  valid_21627393 = validateParameter(valid_21627393, JString, required = false,
                                   default = nil)
  if valid_21627393 != nil:
    section.add "X-Amz-Signature", valid_21627393
  var valid_21627394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627394 = validateParameter(valid_21627394, JString, required = false,
                                   default = nil)
  if valid_21627394 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627394
  var valid_21627395 = header.getOrDefault("X-Amz-Credential")
  valid_21627395 = validateParameter(valid_21627395, JString, required = false,
                                   default = nil)
  if valid_21627395 != nil:
    section.add "X-Amz-Credential", valid_21627395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627397: Call_InviteUsers_21627384; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_21627397.validator(path, query, header, formData, body, _)
  let scheme = call_21627397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627397.makeUrl(scheme.get, call_21627397.host, call_21627397.base,
                               call_21627397.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627397, uri, valid, _)

proc call*(call_21627398: Call_InviteUsers_21627384; accountId: string;
          body: JsonNode; operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21627399 = newJObject()
  var query_21627400 = newJObject()
  var body_21627401 = newJObject()
  add(path_21627399, "accountId", newJString(accountId))
  add(query_21627400, "operation", newJString(operation))
  if body != nil:
    body_21627401 = body
  result = call_21627398.call(path_21627399, query_21627400, nil, nil, body_21627401)

var inviteUsers* = Call_InviteUsers_21627384(name: "inviteUsers",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=add",
    validator: validate_InviteUsers_21627385, base: "/", makeUrl: url_InviteUsers_21627386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_21627402 = ref object of OpenApiRestCall_21625435
proc url_ListPhoneNumbers_21627404(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumbers_21627403(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
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
  var valid_21627405 = query.getOrDefault("filter-name")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = newJString("AccountId"))
  if valid_21627405 != nil:
    section.add "filter-name", valid_21627405
  var valid_21627406 = query.getOrDefault("NextToken")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "NextToken", valid_21627406
  var valid_21627407 = query.getOrDefault("max-results")
  valid_21627407 = validateParameter(valid_21627407, JInt, required = false,
                                   default = nil)
  if valid_21627407 != nil:
    section.add "max-results", valid_21627407
  var valid_21627408 = query.getOrDefault("filter-value")
  valid_21627408 = validateParameter(valid_21627408, JString, required = false,
                                   default = nil)
  if valid_21627408 != nil:
    section.add "filter-value", valid_21627408
  var valid_21627409 = query.getOrDefault("status")
  valid_21627409 = validateParameter(valid_21627409, JString, required = false,
                                   default = newJString("AcquireInProgress"))
  if valid_21627409 != nil:
    section.add "status", valid_21627409
  var valid_21627410 = query.getOrDefault("product-type")
  valid_21627410 = validateParameter(valid_21627410, JString, required = false,
                                   default = newJString("BusinessCalling"))
  if valid_21627410 != nil:
    section.add "product-type", valid_21627410
  var valid_21627411 = query.getOrDefault("next-token")
  valid_21627411 = validateParameter(valid_21627411, JString, required = false,
                                   default = nil)
  if valid_21627411 != nil:
    section.add "next-token", valid_21627411
  var valid_21627412 = query.getOrDefault("MaxResults")
  valid_21627412 = validateParameter(valid_21627412, JString, required = false,
                                   default = nil)
  if valid_21627412 != nil:
    section.add "MaxResults", valid_21627412
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
  var valid_21627413 = header.getOrDefault("X-Amz-Date")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "X-Amz-Date", valid_21627413
  var valid_21627414 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "X-Amz-Security-Token", valid_21627414
  var valid_21627415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627415 = validateParameter(valid_21627415, JString, required = false,
                                   default = nil)
  if valid_21627415 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627415
  var valid_21627416 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "X-Amz-Algorithm", valid_21627416
  var valid_21627417 = header.getOrDefault("X-Amz-Signature")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = nil)
  if valid_21627417 != nil:
    section.add "X-Amz-Signature", valid_21627417
  var valid_21627418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627418
  var valid_21627419 = header.getOrDefault("X-Amz-Credential")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "X-Amz-Credential", valid_21627419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627420: Call_ListPhoneNumbers_21627402; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  let valid = call_21627420.validator(path, query, header, formData, body, _)
  let scheme = call_21627420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627420.makeUrl(scheme.get, call_21627420.host, call_21627420.base,
                               call_21627420.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627420, uri, valid, _)

proc call*(call_21627421: Call_ListPhoneNumbers_21627402;
          filterName: string = "AccountId"; NextToken: string = ""; maxResults: int = 0;
          filterValue: string = ""; status: string = "AcquireInProgress";
          productType: string = "BusinessCalling"; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listPhoneNumbers
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
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
  var query_21627422 = newJObject()
  add(query_21627422, "filter-name", newJString(filterName))
  add(query_21627422, "NextToken", newJString(NextToken))
  add(query_21627422, "max-results", newJInt(maxResults))
  add(query_21627422, "filter-value", newJString(filterValue))
  add(query_21627422, "status", newJString(status))
  add(query_21627422, "product-type", newJString(productType))
  add(query_21627422, "next-token", newJString(nextToken))
  add(query_21627422, "MaxResults", newJString(MaxResults))
  result = call_21627421.call(nil, query_21627422, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_21627402(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_21627403, base: "/",
    makeUrl: url_ListPhoneNumbers_21627404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_21627423 = ref object of OpenApiRestCall_21625435
proc url_ListVoiceConnectorTerminationCredentials_21627425(protocol: Scheme;
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

proc validate_ListVoiceConnectorTerminationCredentials_21627424(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627426 = path.getOrDefault("voiceConnectorId")
  valid_21627426 = validateParameter(valid_21627426, JString, required = true,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "voiceConnectorId", valid_21627426
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
  var valid_21627427 = header.getOrDefault("X-Amz-Date")
  valid_21627427 = validateParameter(valid_21627427, JString, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "X-Amz-Date", valid_21627427
  var valid_21627428 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Security-Token", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627430 = validateParameter(valid_21627430, JString, required = false,
                                   default = nil)
  if valid_21627430 != nil:
    section.add "X-Amz-Algorithm", valid_21627430
  var valid_21627431 = header.getOrDefault("X-Amz-Signature")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "X-Amz-Signature", valid_21627431
  var valid_21627432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627432 = validateParameter(valid_21627432, JString, required = false,
                                   default = nil)
  if valid_21627432 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627432
  var valid_21627433 = header.getOrDefault("X-Amz-Credential")
  valid_21627433 = validateParameter(valid_21627433, JString, required = false,
                                   default = nil)
  if valid_21627433 != nil:
    section.add "X-Amz-Credential", valid_21627433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627434: Call_ListVoiceConnectorTerminationCredentials_21627423;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627434.validator(path, query, header, formData, body, _)
  let scheme = call_21627434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627434.makeUrl(scheme.get, call_21627434.host, call_21627434.base,
                               call_21627434.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627434, uri, valid, _)

proc call*(call_21627435: Call_ListVoiceConnectorTerminationCredentials_21627423;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_21627436 = newJObject()
  add(path_21627436, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_21627435.call(path_21627436, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_21627423(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_21627424,
    base: "/", makeUrl: url_ListVoiceConnectorTerminationCredentials_21627425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_21627437 = ref object of OpenApiRestCall_21625435
proc url_LogoutUser_21627439(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "#operation=logout")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_LogoutUser_21627438(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627440 = path.getOrDefault("accountId")
  valid_21627440 = validateParameter(valid_21627440, JString, required = true,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "accountId", valid_21627440
  var valid_21627441 = path.getOrDefault("userId")
  valid_21627441 = validateParameter(valid_21627441, JString, required = true,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "userId", valid_21627441
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627442 = query.getOrDefault("operation")
  valid_21627442 = validateParameter(valid_21627442, JString, required = true,
                                   default = newJString("logout"))
  if valid_21627442 != nil:
    section.add "operation", valid_21627442
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
  var valid_21627443 = header.getOrDefault("X-Amz-Date")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Date", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-Security-Token", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-Algorithm", valid_21627446
  var valid_21627447 = header.getOrDefault("X-Amz-Signature")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-Signature", valid_21627447
  var valid_21627448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627448 = validateParameter(valid_21627448, JString, required = false,
                                   default = nil)
  if valid_21627448 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627448
  var valid_21627449 = header.getOrDefault("X-Amz-Credential")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "X-Amz-Credential", valid_21627449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627450: Call_LogoutUser_21627437; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_21627450.validator(path, query, header, formData, body, _)
  let scheme = call_21627450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627450.makeUrl(scheme.get, call_21627450.host, call_21627450.base,
                               call_21627450.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627450, uri, valid, _)

proc call*(call_21627451: Call_LogoutUser_21627437; accountId: string;
          userId: string; operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_21627452 = newJObject()
  var query_21627453 = newJObject()
  add(path_21627452, "accountId", newJString(accountId))
  add(query_21627453, "operation", newJString(operation))
  add(path_21627452, "userId", newJString(userId))
  result = call_21627451.call(path_21627452, query_21627453, nil, nil, nil)

var logoutUser* = Call_LogoutUser_21627437(name: "logoutUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                        validator: validate_LogoutUser_21627438,
                                        base: "/", makeUrl: url_LogoutUser_21627439,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_21627454 = ref object of OpenApiRestCall_21625435
proc url_PutVoiceConnectorTerminationCredentials_21627456(protocol: Scheme;
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

proc validate_PutVoiceConnectorTerminationCredentials_21627455(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627457 = path.getOrDefault("voiceConnectorId")
  valid_21627457 = validateParameter(valid_21627457, JString, required = true,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "voiceConnectorId", valid_21627457
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627458 = query.getOrDefault("operation")
  valid_21627458 = validateParameter(valid_21627458, JString, required = true,
                                   default = newJString("put"))
  if valid_21627458 != nil:
    section.add "operation", valid_21627458
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
  var valid_21627459 = header.getOrDefault("X-Amz-Date")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Date", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627460 = validateParameter(valid_21627460, JString, required = false,
                                   default = nil)
  if valid_21627460 != nil:
    section.add "X-Amz-Security-Token", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Algorithm", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-Signature")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-Signature", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627464
  var valid_21627465 = header.getOrDefault("X-Amz-Credential")
  valid_21627465 = validateParameter(valid_21627465, JString, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "X-Amz-Credential", valid_21627465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627467: Call_PutVoiceConnectorTerminationCredentials_21627454;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_21627467.validator(path, query, header, formData, body, _)
  let scheme = call_21627467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627467.makeUrl(scheme.get, call_21627467.host, call_21627467.base,
                               call_21627467.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627467, uri, valid, _)

proc call*(call_21627468: Call_PutVoiceConnectorTerminationCredentials_21627454;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_21627469 = newJObject()
  var query_21627470 = newJObject()
  var body_21627471 = newJObject()
  add(path_21627469, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_21627470, "operation", newJString(operation))
  if body != nil:
    body_21627471 = body
  result = call_21627468.call(path_21627469, query_21627470, nil, nil, body_21627471)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_21627454(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_21627455,
    base: "/", makeUrl: url_PutVoiceConnectorTerminationCredentials_21627456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_21627472 = ref object of OpenApiRestCall_21625435
proc url_RegenerateSecurityToken_21627474(protocol: Scheme; host: string;
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
               (kind: VariableSegment, value: "botId"), (kind: ConstantSegment,
        value: "#operation=regenerate-security-token")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegenerateSecurityToken_21627473(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627475 = path.getOrDefault("accountId")
  valid_21627475 = validateParameter(valid_21627475, JString, required = true,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "accountId", valid_21627475
  var valid_21627476 = path.getOrDefault("botId")
  valid_21627476 = validateParameter(valid_21627476, JString, required = true,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "botId", valid_21627476
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627477 = query.getOrDefault("operation")
  valid_21627477 = validateParameter(valid_21627477, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_21627477 != nil:
    section.add "operation", valid_21627477
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
  var valid_21627478 = header.getOrDefault("X-Amz-Date")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "X-Amz-Date", valid_21627478
  var valid_21627479 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "X-Amz-Security-Token", valid_21627479
  var valid_21627480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627480 = validateParameter(valid_21627480, JString, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627480
  var valid_21627481 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627481 = validateParameter(valid_21627481, JString, required = false,
                                   default = nil)
  if valid_21627481 != nil:
    section.add "X-Amz-Algorithm", valid_21627481
  var valid_21627482 = header.getOrDefault("X-Amz-Signature")
  valid_21627482 = validateParameter(valid_21627482, JString, required = false,
                                   default = nil)
  if valid_21627482 != nil:
    section.add "X-Amz-Signature", valid_21627482
  var valid_21627483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627483 = validateParameter(valid_21627483, JString, required = false,
                                   default = nil)
  if valid_21627483 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627483
  var valid_21627484 = header.getOrDefault("X-Amz-Credential")
  valid_21627484 = validateParameter(valid_21627484, JString, required = false,
                                   default = nil)
  if valid_21627484 != nil:
    section.add "X-Amz-Credential", valid_21627484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627485: Call_RegenerateSecurityToken_21627472;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_21627485.validator(path, query, header, formData, body, _)
  let scheme = call_21627485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627485.makeUrl(scheme.get, call_21627485.host, call_21627485.base,
                               call_21627485.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627485, uri, valid, _)

proc call*(call_21627486: Call_RegenerateSecurityToken_21627472; accountId: string;
          botId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  var path_21627487 = newJObject()
  var query_21627488 = newJObject()
  add(path_21627487, "accountId", newJString(accountId))
  add(path_21627487, "botId", newJString(botId))
  add(query_21627488, "operation", newJString(operation))
  result = call_21627486.call(path_21627487, query_21627488, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_21627472(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_21627473, base: "/",
    makeUrl: url_RegenerateSecurityToken_21627474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_21627489 = ref object of OpenApiRestCall_21625435
proc url_ResetPersonalPIN_21627491(protocol: Scheme; host: string; base: string;
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

proc validate_ResetPersonalPIN_21627490(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627492 = path.getOrDefault("accountId")
  valid_21627492 = validateParameter(valid_21627492, JString, required = true,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "accountId", valid_21627492
  var valid_21627493 = path.getOrDefault("userId")
  valid_21627493 = validateParameter(valid_21627493, JString, required = true,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "userId", valid_21627493
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627494 = query.getOrDefault("operation")
  valid_21627494 = validateParameter(valid_21627494, JString, required = true,
                                   default = newJString("reset-personal-pin"))
  if valid_21627494 != nil:
    section.add "operation", valid_21627494
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
  var valid_21627495 = header.getOrDefault("X-Amz-Date")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "X-Amz-Date", valid_21627495
  var valid_21627496 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627496 = validateParameter(valid_21627496, JString, required = false,
                                   default = nil)
  if valid_21627496 != nil:
    section.add "X-Amz-Security-Token", valid_21627496
  var valid_21627497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627497 = validateParameter(valid_21627497, JString, required = false,
                                   default = nil)
  if valid_21627497 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627497
  var valid_21627498 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627498 = validateParameter(valid_21627498, JString, required = false,
                                   default = nil)
  if valid_21627498 != nil:
    section.add "X-Amz-Algorithm", valid_21627498
  var valid_21627499 = header.getOrDefault("X-Amz-Signature")
  valid_21627499 = validateParameter(valid_21627499, JString, required = false,
                                   default = nil)
  if valid_21627499 != nil:
    section.add "X-Amz-Signature", valid_21627499
  var valid_21627500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627500 = validateParameter(valid_21627500, JString, required = false,
                                   default = nil)
  if valid_21627500 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627500
  var valid_21627501 = header.getOrDefault("X-Amz-Credential")
  valid_21627501 = validateParameter(valid_21627501, JString, required = false,
                                   default = nil)
  if valid_21627501 != nil:
    section.add "X-Amz-Credential", valid_21627501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627502: Call_ResetPersonalPIN_21627489; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_21627502.validator(path, query, header, formData, body, _)
  let scheme = call_21627502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627502.makeUrl(scheme.get, call_21627502.host, call_21627502.base,
                               call_21627502.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627502, uri, valid, _)

proc call*(call_21627503: Call_ResetPersonalPIN_21627489; accountId: string;
          userId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_21627504 = newJObject()
  var query_21627505 = newJObject()
  add(path_21627504, "accountId", newJString(accountId))
  add(query_21627505, "operation", newJString(operation))
  add(path_21627504, "userId", newJString(userId))
  result = call_21627503.call(path_21627504, query_21627505, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_21627489(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_21627490, base: "/",
    makeUrl: url_ResetPersonalPIN_21627491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_21627506 = ref object of OpenApiRestCall_21625435
proc url_RestorePhoneNumber_21627508(protocol: Scheme; host: string; base: string;
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

proc validate_RestorePhoneNumber_21627507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627509 = path.getOrDefault("phoneNumberId")
  valid_21627509 = validateParameter(valid_21627509, JString, required = true,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "phoneNumberId", valid_21627509
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  var valid_21627510 = query.getOrDefault("operation")
  valid_21627510 = validateParameter(valid_21627510, JString, required = true,
                                   default = newJString("restore"))
  if valid_21627510 != nil:
    section.add "operation", valid_21627510
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
  var valid_21627511 = header.getOrDefault("X-Amz-Date")
  valid_21627511 = validateParameter(valid_21627511, JString, required = false,
                                   default = nil)
  if valid_21627511 != nil:
    section.add "X-Amz-Date", valid_21627511
  var valid_21627512 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627512 = validateParameter(valid_21627512, JString, required = false,
                                   default = nil)
  if valid_21627512 != nil:
    section.add "X-Amz-Security-Token", valid_21627512
  var valid_21627513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627513 = validateParameter(valid_21627513, JString, required = false,
                                   default = nil)
  if valid_21627513 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627513
  var valid_21627514 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627514 = validateParameter(valid_21627514, JString, required = false,
                                   default = nil)
  if valid_21627514 != nil:
    section.add "X-Amz-Algorithm", valid_21627514
  var valid_21627515 = header.getOrDefault("X-Amz-Signature")
  valid_21627515 = validateParameter(valid_21627515, JString, required = false,
                                   default = nil)
  if valid_21627515 != nil:
    section.add "X-Amz-Signature", valid_21627515
  var valid_21627516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627516 = validateParameter(valid_21627516, JString, required = false,
                                   default = nil)
  if valid_21627516 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627516
  var valid_21627517 = header.getOrDefault("X-Amz-Credential")
  valid_21627517 = validateParameter(valid_21627517, JString, required = false,
                                   default = nil)
  if valid_21627517 != nil:
    section.add "X-Amz-Credential", valid_21627517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627518: Call_RestorePhoneNumber_21627506; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_21627518.validator(path, query, header, formData, body, _)
  let scheme = call_21627518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627518.makeUrl(scheme.get, call_21627518.host, call_21627518.base,
                               call_21627518.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627518, uri, valid, _)

proc call*(call_21627519: Call_RestorePhoneNumber_21627506; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_21627520 = newJObject()
  var query_21627521 = newJObject()
  add(path_21627520, "phoneNumberId", newJString(phoneNumberId))
  add(query_21627521, "operation", newJString(operation))
  result = call_21627519.call(path_21627520, query_21627521, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_21627506(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_21627507, base: "/",
    makeUrl: url_RestorePhoneNumber_21627508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_21627522 = ref object of OpenApiRestCall_21625435
proc url_SearchAvailablePhoneNumbers_21627524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchAvailablePhoneNumbers_21627523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627525 = query.getOrDefault("city")
  valid_21627525 = validateParameter(valid_21627525, JString, required = false,
                                   default = nil)
  if valid_21627525 != nil:
    section.add "city", valid_21627525
  var valid_21627526 = query.getOrDefault("toll-free-prefix")
  valid_21627526 = validateParameter(valid_21627526, JString, required = false,
                                   default = nil)
  if valid_21627526 != nil:
    section.add "toll-free-prefix", valid_21627526
  var valid_21627527 = query.getOrDefault("country")
  valid_21627527 = validateParameter(valid_21627527, JString, required = false,
                                   default = nil)
  if valid_21627527 != nil:
    section.add "country", valid_21627527
  var valid_21627528 = query.getOrDefault("area-code")
  valid_21627528 = validateParameter(valid_21627528, JString, required = false,
                                   default = nil)
  if valid_21627528 != nil:
    section.add "area-code", valid_21627528
  var valid_21627529 = query.getOrDefault("type")
  valid_21627529 = validateParameter(valid_21627529, JString, required = true,
                                   default = newJString("phone-numbers"))
  if valid_21627529 != nil:
    section.add "type", valid_21627529
  var valid_21627530 = query.getOrDefault("max-results")
  valid_21627530 = validateParameter(valid_21627530, JInt, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "max-results", valid_21627530
  var valid_21627531 = query.getOrDefault("next-token")
  valid_21627531 = validateParameter(valid_21627531, JString, required = false,
                                   default = nil)
  if valid_21627531 != nil:
    section.add "next-token", valid_21627531
  var valid_21627532 = query.getOrDefault("state")
  valid_21627532 = validateParameter(valid_21627532, JString, required = false,
                                   default = nil)
  if valid_21627532 != nil:
    section.add "state", valid_21627532
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
  var valid_21627533 = header.getOrDefault("X-Amz-Date")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-Date", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627534 = validateParameter(valid_21627534, JString, required = false,
                                   default = nil)
  if valid_21627534 != nil:
    section.add "X-Amz-Security-Token", valid_21627534
  var valid_21627535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627535 = validateParameter(valid_21627535, JString, required = false,
                                   default = nil)
  if valid_21627535 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-Algorithm", valid_21627536
  var valid_21627537 = header.getOrDefault("X-Amz-Signature")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "X-Amz-Signature", valid_21627537
  var valid_21627538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627538 = validateParameter(valid_21627538, JString, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627538
  var valid_21627539 = header.getOrDefault("X-Amz-Credential")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "X-Amz-Credential", valid_21627539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627540: Call_SearchAvailablePhoneNumbers_21627522;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_21627540.validator(path, query, header, formData, body, _)
  let scheme = call_21627540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627540.makeUrl(scheme.get, call_21627540.host, call_21627540.base,
                               call_21627540.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627540, uri, valid, _)

proc call*(call_21627541: Call_SearchAvailablePhoneNumbers_21627522;
          city: string = ""; tollFreePrefix: string = ""; country: string = "";
          areaCode: string = ""; `type`: string = "phone-numbers"; maxResults: int = 0;
          nextToken: string = ""; state: string = ""): Recallable =
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
  var query_21627542 = newJObject()
  add(query_21627542, "city", newJString(city))
  add(query_21627542, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_21627542, "country", newJString(country))
  add(query_21627542, "area-code", newJString(areaCode))
  add(query_21627542, "type", newJString(`type`))
  add(query_21627542, "max-results", newJInt(maxResults))
  add(query_21627542, "next-token", newJString(nextToken))
  add(query_21627542, "state", newJString(state))
  result = call_21627541.call(nil, query_21627542, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_21627522(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_21627523, base: "/",
    makeUrl: url_SearchAvailablePhoneNumbers_21627524,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}