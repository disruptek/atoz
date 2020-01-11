
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

  OpenApiRestCall_603389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_603389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_603389): Option[Scheme] {.used.} =
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
  Call_AssociatePhoneNumberWithUser_603727 = ref object of OpenApiRestCall_603389
proc url_AssociatePhoneNumberWithUser_603729(protocol: Scheme; host: string;
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

proc validate_AssociatePhoneNumberWithUser_603728(path: JsonNode; query: JsonNode;
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
  var valid_603855 = path.getOrDefault("userId")
  valid_603855 = validateParameter(valid_603855, JString, required = true,
                                 default = nil)
  if valid_603855 != nil:
    section.add "userId", valid_603855
  var valid_603856 = path.getOrDefault("accountId")
  valid_603856 = validateParameter(valid_603856, JString, required = true,
                                 default = nil)
  if valid_603856 != nil:
    section.add "accountId", valid_603856
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603870 = query.getOrDefault("operation")
  valid_603870 = validateParameter(valid_603870, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_603870 != nil:
    section.add "operation", valid_603870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603871 = header.getOrDefault("X-Amz-Signature")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Signature", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Content-Sha256", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Date")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Date", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Credential")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Credential", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Security-Token")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Security-Token", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Algorithm")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Algorithm", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-SignedHeaders", valid_603877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603901: Call_AssociatePhoneNumberWithUser_603727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_603901.validator(path, query, header, formData, body)
  let scheme = call_603901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603901.url(scheme.get, call_603901.host, call_603901.base,
                         call_603901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603901, url, valid)

proc call*(call_603972: Call_AssociatePhoneNumberWithUser_603727; userId: string;
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
  var path_603973 = newJObject()
  var query_603975 = newJObject()
  var body_603976 = newJObject()
  add(query_603975, "operation", newJString(operation))
  add(path_603973, "userId", newJString(userId))
  if body != nil:
    body_603976 = body
  add(path_603973, "accountId", newJString(accountId))
  result = call_603972.call(path_603973, query_603975, nil, nil, body_603976)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_603727(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_603728, base: "/",
    url: url_AssociatePhoneNumberWithUser_603729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_604015 = ref object of OpenApiRestCall_603389
proc url_AssociatePhoneNumbersWithVoiceConnector_604017(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnector_604016(path: JsonNode;
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
  var valid_604018 = path.getOrDefault("voiceConnectorId")
  valid_604018 = validateParameter(valid_604018, JString, required = true,
                                 default = nil)
  if valid_604018 != nil:
    section.add "voiceConnectorId", valid_604018
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604019 = query.getOrDefault("operation")
  valid_604019 = validateParameter(valid_604019, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_604019 != nil:
    section.add "operation", valid_604019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604020 = header.getOrDefault("X-Amz-Signature")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Signature", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Content-Sha256", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Date")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Date", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Credential")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Credential", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Security-Token")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Security-Token", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Algorithm")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Algorithm", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-SignedHeaders", valid_604026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604028: Call_AssociatePhoneNumbersWithVoiceConnector_604015;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_604028.validator(path, query, header, formData, body)
  let scheme = call_604028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604028.url(scheme.get, call_604028.host, call_604028.base,
                         call_604028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604028, url, valid)

proc call*(call_604029: Call_AssociatePhoneNumbersWithVoiceConnector_604015;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_604030 = newJObject()
  var query_604031 = newJObject()
  var body_604032 = newJObject()
  add(query_604031, "operation", newJString(operation))
  add(path_604030, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_604032 = body
  result = call_604029.call(path_604030, query_604031, nil, nil, body_604032)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_604015(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_604016, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_604017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnectorGroup_604033 = ref object of OpenApiRestCall_603389
proc url_AssociatePhoneNumbersWithVoiceConnectorGroup_604035(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnectorGroup_604034(path: JsonNode;
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
  var valid_604036 = path.getOrDefault("voiceConnectorGroupId")
  valid_604036 = validateParameter(valid_604036, JString, required = true,
                                 default = nil)
  if valid_604036 != nil:
    section.add "voiceConnectorGroupId", valid_604036
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604037 = query.getOrDefault("operation")
  valid_604037 = validateParameter(valid_604037, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_604037 != nil:
    section.add "operation", valid_604037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604038 = header.getOrDefault("X-Amz-Signature")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Signature", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Content-Sha256", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Date")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Date", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Credential")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Credential", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Security-Token")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Security-Token", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Algorithm")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Algorithm", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-SignedHeaders", valid_604044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604046: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_604033;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_604046.validator(path, query, header, formData, body)
  let scheme = call_604046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604046.url(scheme.get, call_604046.host, call_604046.base,
                         call_604046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604046, url, valid)

proc call*(call_604047: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_604033;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnectorGroup
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_604048 = newJObject()
  var query_604049 = newJObject()
  var body_604050 = newJObject()
  add(path_604048, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_604049, "operation", newJString(operation))
  if body != nil:
    body_604050 = body
  result = call_604047.call(path_604048, query_604049, nil, nil, body_604050)

var associatePhoneNumbersWithVoiceConnectorGroup* = Call_AssociatePhoneNumbersWithVoiceConnectorGroup_604033(
    name: "associatePhoneNumbersWithVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnectorGroup_604034,
    base: "/", url: url_AssociatePhoneNumbersWithVoiceConnectorGroup_604035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSigninDelegateGroupsWithAccount_604051 = ref object of OpenApiRestCall_603389
proc url_AssociateSigninDelegateGroupsWithAccount_604053(protocol: Scheme;
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

proc validate_AssociateSigninDelegateGroupsWithAccount_604052(path: JsonNode;
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
  var valid_604054 = path.getOrDefault("accountId")
  valid_604054 = validateParameter(valid_604054, JString, required = true,
                                 default = nil)
  if valid_604054 != nil:
    section.add "accountId", valid_604054
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604055 = query.getOrDefault("operation")
  valid_604055 = validateParameter(valid_604055, JString, required = true, default = newJString(
      "associate-signin-delegate-groups"))
  if valid_604055 != nil:
    section.add "operation", valid_604055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604056 = header.getOrDefault("X-Amz-Signature")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Signature", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Content-Sha256", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Date")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Date", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Credential")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Credential", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Security-Token")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Security-Token", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Algorithm")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Algorithm", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-SignedHeaders", valid_604062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604064: Call_AssociateSigninDelegateGroupsWithAccount_604051;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ## 
  let valid = call_604064.validator(path, query, header, formData, body)
  let scheme = call_604064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604064.url(scheme.get, call_604064.host, call_604064.base,
                         call_604064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604064, url, valid)

proc call*(call_604065: Call_AssociateSigninDelegateGroupsWithAccount_604051;
          body: JsonNode; accountId: string;
          operation: string = "associate-signin-delegate-groups"): Recallable =
  ## associateSigninDelegateGroupsWithAccount
  ## Associates the specified sign-in delegate groups with the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604066 = newJObject()
  var query_604067 = newJObject()
  var body_604068 = newJObject()
  add(query_604067, "operation", newJString(operation))
  if body != nil:
    body_604068 = body
  add(path_604066, "accountId", newJString(accountId))
  result = call_604065.call(path_604066, query_604067, nil, nil, body_604068)

var associateSigninDelegateGroupsWithAccount* = Call_AssociateSigninDelegateGroupsWithAccount_604051(
    name: "associateSigninDelegateGroupsWithAccount", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}#operation=associate-signin-delegate-groups",
    validator: validate_AssociateSigninDelegateGroupsWithAccount_604052,
    base: "/", url: url_AssociateSigninDelegateGroupsWithAccount_604053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateAttendee_604069 = ref object of OpenApiRestCall_603389
proc url_BatchCreateAttendee_604071(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreateAttendee_604070(path: JsonNode; query: JsonNode;
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
  var valid_604072 = path.getOrDefault("meetingId")
  valid_604072 = validateParameter(valid_604072, JString, required = true,
                                 default = nil)
  if valid_604072 != nil:
    section.add "meetingId", valid_604072
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604073 = query.getOrDefault("operation")
  valid_604073 = validateParameter(valid_604073, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_604073 != nil:
    section.add "operation", valid_604073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604074 = header.getOrDefault("X-Amz-Signature")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Signature", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Content-Sha256", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Date")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Date", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Credential")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Credential", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Security-Token")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Security-Token", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Algorithm")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Algorithm", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-SignedHeaders", valid_604080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604082: Call_BatchCreateAttendee_604069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  let valid = call_604082.validator(path, query, header, formData, body)
  let scheme = call_604082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604082.url(scheme.get, call_604082.host, call_604082.base,
                         call_604082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604082, url, valid)

proc call*(call_604083: Call_BatchCreateAttendee_604069; body: JsonNode;
          meetingId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateAttendee
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_604084 = newJObject()
  var query_604085 = newJObject()
  var body_604086 = newJObject()
  add(query_604085, "operation", newJString(operation))
  if body != nil:
    body_604086 = body
  add(path_604084, "meetingId", newJString(meetingId))
  result = call_604083.call(path_604084, query_604085, nil, nil, body_604086)

var batchCreateAttendee* = Call_BatchCreateAttendee_604069(
    name: "batchCreateAttendee", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees#operation=batch-create",
    validator: validate_BatchCreateAttendee_604070, base: "/",
    url: url_BatchCreateAttendee_604071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateRoomMembership_604087 = ref object of OpenApiRestCall_603389
proc url_BatchCreateRoomMembership_604089(protocol: Scheme; host: string;
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

proc validate_BatchCreateRoomMembership_604088(path: JsonNode; query: JsonNode;
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
  var valid_604090 = path.getOrDefault("accountId")
  valid_604090 = validateParameter(valid_604090, JString, required = true,
                                 default = nil)
  if valid_604090 != nil:
    section.add "accountId", valid_604090
  var valid_604091 = path.getOrDefault("roomId")
  valid_604091 = validateParameter(valid_604091, JString, required = true,
                                 default = nil)
  if valid_604091 != nil:
    section.add "roomId", valid_604091
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604092 = query.getOrDefault("operation")
  valid_604092 = validateParameter(valid_604092, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_604092 != nil:
    section.add "operation", valid_604092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604093 = header.getOrDefault("X-Amz-Signature")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Signature", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Content-Sha256", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Date")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Date", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Credential")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Credential", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Security-Token")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Security-Token", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Algorithm")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Algorithm", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-SignedHeaders", valid_604099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604101: Call_BatchCreateRoomMembership_604087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_604101.validator(path, query, header, formData, body)
  let scheme = call_604101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604101.url(scheme.get, call_604101.host, call_604101.base,
                         call_604101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604101, url, valid)

proc call*(call_604102: Call_BatchCreateRoomMembership_604087; body: JsonNode;
          accountId: string; roomId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateRoomMembership
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_604103 = newJObject()
  var query_604104 = newJObject()
  var body_604105 = newJObject()
  add(query_604104, "operation", newJString(operation))
  if body != nil:
    body_604105 = body
  add(path_604103, "accountId", newJString(accountId))
  add(path_604103, "roomId", newJString(roomId))
  result = call_604102.call(path_604103, query_604104, nil, nil, body_604105)

var batchCreateRoomMembership* = Call_BatchCreateRoomMembership_604087(
    name: "batchCreateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}/memberships#operation=batch-create",
    validator: validate_BatchCreateRoomMembership_604088, base: "/",
    url: url_BatchCreateRoomMembership_604089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_604106 = ref object of OpenApiRestCall_603389
proc url_BatchDeletePhoneNumber_604108(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeletePhoneNumber_604107(path: JsonNode; query: JsonNode;
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
  var valid_604109 = query.getOrDefault("operation")
  valid_604109 = validateParameter(valid_604109, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_604109 != nil:
    section.add "operation", valid_604109
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604110 = header.getOrDefault("X-Amz-Signature")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Signature", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Content-Sha256", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Date")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Date", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Credential")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Credential", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Security-Token")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Security-Token", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Algorithm")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Algorithm", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-SignedHeaders", valid_604116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604118: Call_BatchDeletePhoneNumber_604106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_604118.validator(path, query, header, formData, body)
  let scheme = call_604118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604118.url(scheme.get, call_604118.host, call_604118.base,
                         call_604118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604118, url, valid)

proc call*(call_604119: Call_BatchDeletePhoneNumber_604106; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_604120 = newJObject()
  var body_604121 = newJObject()
  add(query_604120, "operation", newJString(operation))
  if body != nil:
    body_604121 = body
  result = call_604119.call(nil, query_604120, nil, nil, body_604121)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_604106(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_604107, base: "/",
    url: url_BatchDeletePhoneNumber_604108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_604122 = ref object of OpenApiRestCall_603389
proc url_BatchSuspendUser_604124(protocol: Scheme; host: string; base: string;
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

proc validate_BatchSuspendUser_604123(path: JsonNode; query: JsonNode;
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
  var valid_604125 = path.getOrDefault("accountId")
  valid_604125 = validateParameter(valid_604125, JString, required = true,
                                 default = nil)
  if valid_604125 != nil:
    section.add "accountId", valid_604125
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604126 = query.getOrDefault("operation")
  valid_604126 = validateParameter(valid_604126, JString, required = true,
                                 default = newJString("suspend"))
  if valid_604126 != nil:
    section.add "operation", valid_604126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604127 = header.getOrDefault("X-Amz-Signature")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Signature", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Content-Sha256", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Date")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Date", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Credential")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Credential", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Security-Token")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Security-Token", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Algorithm")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Algorithm", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-SignedHeaders", valid_604133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604135: Call_BatchSuspendUser_604122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_604135.validator(path, query, header, formData, body)
  let scheme = call_604135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604135.url(scheme.get, call_604135.host, call_604135.base,
                         call_604135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604135, url, valid)

proc call*(call_604136: Call_BatchSuspendUser_604122; body: JsonNode;
          accountId: string; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are disassociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604137 = newJObject()
  var query_604138 = newJObject()
  var body_604139 = newJObject()
  add(query_604138, "operation", newJString(operation))
  if body != nil:
    body_604139 = body
  add(path_604137, "accountId", newJString(accountId))
  result = call_604136.call(path_604137, query_604138, nil, nil, body_604139)

var batchSuspendUser* = Call_BatchSuspendUser_604122(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_604123, base: "/",
    url: url_BatchSuspendUser_604124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_604140 = ref object of OpenApiRestCall_603389
proc url_BatchUnsuspendUser_604142(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUnsuspendUser_604141(path: JsonNode; query: JsonNode;
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
  var valid_604143 = path.getOrDefault("accountId")
  valid_604143 = validateParameter(valid_604143, JString, required = true,
                                 default = nil)
  if valid_604143 != nil:
    section.add "accountId", valid_604143
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604144 = query.getOrDefault("operation")
  valid_604144 = validateParameter(valid_604144, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_604144 != nil:
    section.add "operation", valid_604144
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604145 = header.getOrDefault("X-Amz-Signature")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Signature", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Content-Sha256", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Date")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Date", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Credential")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Credential", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-Security-Token")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-Security-Token", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Algorithm")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Algorithm", valid_604150
  var valid_604151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "X-Amz-SignedHeaders", valid_604151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604153: Call_BatchUnsuspendUser_604140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_604153.validator(path, query, header, formData, body)
  let scheme = call_604153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604153.url(scheme.get, call_604153.host, call_604153.base,
                         call_604153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604153, url, valid)

proc call*(call_604154: Call_BatchUnsuspendUser_604140; body: JsonNode;
          accountId: string; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604155 = newJObject()
  var query_604156 = newJObject()
  var body_604157 = newJObject()
  add(query_604156, "operation", newJString(operation))
  if body != nil:
    body_604157 = body
  add(path_604155, "accountId", newJString(accountId))
  result = call_604154.call(path_604155, query_604156, nil, nil, body_604157)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_604140(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_604141, base: "/",
    url: url_BatchUnsuspendUser_604142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_604158 = ref object of OpenApiRestCall_603389
proc url_BatchUpdatePhoneNumber_604160(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdatePhoneNumber_604159(path: JsonNode; query: JsonNode;
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
  var valid_604161 = query.getOrDefault("operation")
  valid_604161 = validateParameter(valid_604161, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_604161 != nil:
    section.add "operation", valid_604161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604162 = header.getOrDefault("X-Amz-Signature")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Signature", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Content-Sha256", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-Date")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Date", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Credential")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Credential", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Security-Token")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Security-Token", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-Algorithm")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Algorithm", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-SignedHeaders", valid_604168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604170: Call_BatchUpdatePhoneNumber_604158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_604170.validator(path, query, header, formData, body)
  let scheme = call_604170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604170.url(scheme.get, call_604170.host, call_604170.base,
                         call_604170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604170, url, valid)

proc call*(call_604171: Call_BatchUpdatePhoneNumber_604158; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_604172 = newJObject()
  var body_604173 = newJObject()
  add(query_604172, "operation", newJString(operation))
  if body != nil:
    body_604173 = body
  result = call_604171.call(nil, query_604172, nil, nil, body_604173)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_604158(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_604159, base: "/",
    url: url_BatchUpdatePhoneNumber_604160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_604195 = ref object of OpenApiRestCall_603389
proc url_BatchUpdateUser_604197(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateUser_604196(path: JsonNode; query: JsonNode;
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
  var valid_604198 = path.getOrDefault("accountId")
  valid_604198 = validateParameter(valid_604198, JString, required = true,
                                 default = nil)
  if valid_604198 != nil:
    section.add "accountId", valid_604198
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
  var valid_604199 = header.getOrDefault("X-Amz-Signature")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Signature", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Content-Sha256", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Date")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Date", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-Credential")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Credential", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Security-Token")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Security-Token", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Algorithm")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Algorithm", valid_604204
  var valid_604205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-SignedHeaders", valid_604205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604207: Call_BatchUpdateUser_604195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_604207.validator(path, query, header, formData, body)
  let scheme = call_604207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604207.url(scheme.get, call_604207.host, call_604207.base,
                         call_604207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604207, url, valid)

proc call*(call_604208: Call_BatchUpdateUser_604195; body: JsonNode;
          accountId: string): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604209 = newJObject()
  var body_604210 = newJObject()
  if body != nil:
    body_604210 = body
  add(path_604209, "accountId", newJString(accountId))
  result = call_604208.call(path_604209, nil, nil, nil, body_604210)

var batchUpdateUser* = Call_BatchUpdateUser_604195(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_604196,
    base: "/", url: url_BatchUpdateUser_604197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_604174 = ref object of OpenApiRestCall_603389
proc url_ListUsers_604176(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_604175(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604177 = path.getOrDefault("accountId")
  valid_604177 = validateParameter(valid_604177, JString, required = true,
                                 default = nil)
  if valid_604177 != nil:
    section.add "accountId", valid_604177
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
  var valid_604178 = query.getOrDefault("MaxResults")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "MaxResults", valid_604178
  var valid_604179 = query.getOrDefault("user-email")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "user-email", valid_604179
  var valid_604180 = query.getOrDefault("NextToken")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "NextToken", valid_604180
  var valid_604181 = query.getOrDefault("user-type")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = newJString("PrivateUser"))
  if valid_604181 != nil:
    section.add "user-type", valid_604181
  var valid_604182 = query.getOrDefault("max-results")
  valid_604182 = validateParameter(valid_604182, JInt, required = false, default = nil)
  if valid_604182 != nil:
    section.add "max-results", valid_604182
  var valid_604183 = query.getOrDefault("next-token")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "next-token", valid_604183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604184 = header.getOrDefault("X-Amz-Signature")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-Signature", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Content-Sha256", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-Date")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Date", valid_604186
  var valid_604187 = header.getOrDefault("X-Amz-Credential")
  valid_604187 = validateParameter(valid_604187, JString, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "X-Amz-Credential", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Security-Token")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Security-Token", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Algorithm")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Algorithm", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-SignedHeaders", valid_604190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604191: Call_ListUsers_604174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_604191.validator(path, query, header, formData, body)
  let scheme = call_604191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604191.url(scheme.get, call_604191.host, call_604191.base,
                         call_604191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604191, url, valid)

proc call*(call_604192: Call_ListUsers_604174; accountId: string;
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
  var path_604193 = newJObject()
  var query_604194 = newJObject()
  add(query_604194, "MaxResults", newJString(MaxResults))
  add(query_604194, "user-email", newJString(userEmail))
  add(query_604194, "NextToken", newJString(NextToken))
  add(query_604194, "user-type", newJString(userType))
  add(query_604194, "max-results", newJInt(maxResults))
  add(path_604193, "accountId", newJString(accountId))
  add(query_604194, "next-token", newJString(nextToken))
  result = call_604192.call(path_604193, query_604194, nil, nil, nil)

var listUsers* = Call_ListUsers_604174(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_604175,
                                    base: "/", url: url_ListUsers_604176,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_604230 = ref object of OpenApiRestCall_603389
proc url_CreateAccount_604232(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAccount_604231(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604233 = header.getOrDefault("X-Amz-Signature")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Signature", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Content-Sha256", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Date")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Date", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-Credential")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-Credential", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-Security-Token")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-Security-Token", valid_604237
  var valid_604238 = header.getOrDefault("X-Amz-Algorithm")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Algorithm", valid_604238
  var valid_604239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604239 = validateParameter(valid_604239, JString, required = false,
                                 default = nil)
  if valid_604239 != nil:
    section.add "X-Amz-SignedHeaders", valid_604239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604241: Call_CreateAccount_604230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_604241.validator(path, query, header, formData, body)
  let scheme = call_604241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604241.url(scheme.get, call_604241.host, call_604241.base,
                         call_604241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604241, url, valid)

proc call*(call_604242: Call_CreateAccount_604230; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_604243 = newJObject()
  if body != nil:
    body_604243 = body
  result = call_604242.call(nil, nil, nil, nil, body_604243)

var createAccount* = Call_CreateAccount_604230(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_604231, base: "/", url: url_CreateAccount_604232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_604211 = ref object of OpenApiRestCall_603389
proc url_ListAccounts_604213(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccounts_604212(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604214 = query.getOrDefault("name")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "name", valid_604214
  var valid_604215 = query.getOrDefault("MaxResults")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "MaxResults", valid_604215
  var valid_604216 = query.getOrDefault("user-email")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "user-email", valid_604216
  var valid_604217 = query.getOrDefault("NextToken")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "NextToken", valid_604217
  var valid_604218 = query.getOrDefault("max-results")
  valid_604218 = validateParameter(valid_604218, JInt, required = false, default = nil)
  if valid_604218 != nil:
    section.add "max-results", valid_604218
  var valid_604219 = query.getOrDefault("next-token")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "next-token", valid_604219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604220 = header.getOrDefault("X-Amz-Signature")
  valid_604220 = validateParameter(valid_604220, JString, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "X-Amz-Signature", valid_604220
  var valid_604221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "X-Amz-Content-Sha256", valid_604221
  var valid_604222 = header.getOrDefault("X-Amz-Date")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "X-Amz-Date", valid_604222
  var valid_604223 = header.getOrDefault("X-Amz-Credential")
  valid_604223 = validateParameter(valid_604223, JString, required = false,
                                 default = nil)
  if valid_604223 != nil:
    section.add "X-Amz-Credential", valid_604223
  var valid_604224 = header.getOrDefault("X-Amz-Security-Token")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "X-Amz-Security-Token", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Algorithm")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Algorithm", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-SignedHeaders", valid_604226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604227: Call_ListAccounts_604211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_604227.validator(path, query, header, formData, body)
  let scheme = call_604227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604227.url(scheme.get, call_604227.host, call_604227.base,
                         call_604227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604227, url, valid)

proc call*(call_604228: Call_ListAccounts_604211; name: string = "";
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
  var query_604229 = newJObject()
  add(query_604229, "name", newJString(name))
  add(query_604229, "MaxResults", newJString(MaxResults))
  add(query_604229, "user-email", newJString(userEmail))
  add(query_604229, "NextToken", newJString(NextToken))
  add(query_604229, "max-results", newJInt(maxResults))
  add(query_604229, "next-token", newJString(nextToken))
  result = call_604228.call(nil, query_604229, nil, nil, nil)

var listAccounts* = Call_ListAccounts_604211(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_604212, base: "/", url: url_ListAccounts_604213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAttendee_604263 = ref object of OpenApiRestCall_603389
proc url_CreateAttendee_604265(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAttendee_604264(path: JsonNode; query: JsonNode;
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
  var valid_604266 = path.getOrDefault("meetingId")
  valid_604266 = validateParameter(valid_604266, JString, required = true,
                                 default = nil)
  if valid_604266 != nil:
    section.add "meetingId", valid_604266
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
  var valid_604267 = header.getOrDefault("X-Amz-Signature")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Signature", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Content-Sha256", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Date")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Date", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-Credential")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-Credential", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Security-Token")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Security-Token", valid_604271
  var valid_604272 = header.getOrDefault("X-Amz-Algorithm")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "X-Amz-Algorithm", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-SignedHeaders", valid_604273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604275: Call_CreateAttendee_604263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604275.validator(path, query, header, formData, body)
  let scheme = call_604275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604275.url(scheme.get, call_604275.host, call_604275.base,
                         call_604275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604275, url, valid)

proc call*(call_604276: Call_CreateAttendee_604263; body: JsonNode; meetingId: string): Recallable =
  ## createAttendee
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_604277 = newJObject()
  var body_604278 = newJObject()
  if body != nil:
    body_604278 = body
  add(path_604277, "meetingId", newJString(meetingId))
  result = call_604276.call(path_604277, nil, nil, nil, body_604278)

var createAttendee* = Call_CreateAttendee_604263(name: "createAttendee",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_CreateAttendee_604264,
    base: "/", url: url_CreateAttendee_604265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttendees_604244 = ref object of OpenApiRestCall_603389
proc url_ListAttendees_604246(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttendees_604245(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604247 = path.getOrDefault("meetingId")
  valid_604247 = validateParameter(valid_604247, JString, required = true,
                                 default = nil)
  if valid_604247 != nil:
    section.add "meetingId", valid_604247
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
  var valid_604248 = query.getOrDefault("MaxResults")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "MaxResults", valid_604248
  var valid_604249 = query.getOrDefault("NextToken")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "NextToken", valid_604249
  var valid_604250 = query.getOrDefault("max-results")
  valid_604250 = validateParameter(valid_604250, JInt, required = false, default = nil)
  if valid_604250 != nil:
    section.add "max-results", valid_604250
  var valid_604251 = query.getOrDefault("next-token")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "next-token", valid_604251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604252 = header.getOrDefault("X-Amz-Signature")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-Signature", valid_604252
  var valid_604253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Content-Sha256", valid_604253
  var valid_604254 = header.getOrDefault("X-Amz-Date")
  valid_604254 = validateParameter(valid_604254, JString, required = false,
                                 default = nil)
  if valid_604254 != nil:
    section.add "X-Amz-Date", valid_604254
  var valid_604255 = header.getOrDefault("X-Amz-Credential")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "X-Amz-Credential", valid_604255
  var valid_604256 = header.getOrDefault("X-Amz-Security-Token")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "X-Amz-Security-Token", valid_604256
  var valid_604257 = header.getOrDefault("X-Amz-Algorithm")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "X-Amz-Algorithm", valid_604257
  var valid_604258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-SignedHeaders", valid_604258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604259: Call_ListAttendees_604244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604259.validator(path, query, header, formData, body)
  let scheme = call_604259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604259.url(scheme.get, call_604259.host, call_604259.base,
                         call_604259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604259, url, valid)

proc call*(call_604260: Call_ListAttendees_604244; meetingId: string;
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
  var path_604261 = newJObject()
  var query_604262 = newJObject()
  add(query_604262, "MaxResults", newJString(MaxResults))
  add(query_604262, "NextToken", newJString(NextToken))
  add(query_604262, "max-results", newJInt(maxResults))
  add(path_604261, "meetingId", newJString(meetingId))
  add(query_604262, "next-token", newJString(nextToken))
  result = call_604260.call(path_604261, query_604262, nil, nil, nil)

var listAttendees* = Call_ListAttendees_604244(name: "listAttendees",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_ListAttendees_604245,
    base: "/", url: url_ListAttendees_604246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_604298 = ref object of OpenApiRestCall_603389
proc url_CreateBot_604300(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateBot_604299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604301 = path.getOrDefault("accountId")
  valid_604301 = validateParameter(valid_604301, JString, required = true,
                                 default = nil)
  if valid_604301 != nil:
    section.add "accountId", valid_604301
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
  var valid_604302 = header.getOrDefault("X-Amz-Signature")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Signature", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-Content-Sha256", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Date")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Date", valid_604304
  var valid_604305 = header.getOrDefault("X-Amz-Credential")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "X-Amz-Credential", valid_604305
  var valid_604306 = header.getOrDefault("X-Amz-Security-Token")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-Security-Token", valid_604306
  var valid_604307 = header.getOrDefault("X-Amz-Algorithm")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "X-Amz-Algorithm", valid_604307
  var valid_604308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "X-Amz-SignedHeaders", valid_604308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604310: Call_CreateBot_604298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_604310.validator(path, query, header, formData, body)
  let scheme = call_604310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604310.url(scheme.get, call_604310.host, call_604310.base,
                         call_604310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604310, url, valid)

proc call*(call_604311: Call_CreateBot_604298; body: JsonNode; accountId: string): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604312 = newJObject()
  var body_604313 = newJObject()
  if body != nil:
    body_604313 = body
  add(path_604312, "accountId", newJString(accountId))
  result = call_604311.call(path_604312, nil, nil, nil, body_604313)

var createBot* = Call_CreateBot_604298(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_604299,
                                    base: "/", url: url_CreateBot_604300,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_604279 = ref object of OpenApiRestCall_603389
proc url_ListBots_604281(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListBots_604280(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604282 = path.getOrDefault("accountId")
  valid_604282 = validateParameter(valid_604282, JString, required = true,
                                 default = nil)
  if valid_604282 != nil:
    section.add "accountId", valid_604282
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
  var valid_604283 = query.getOrDefault("MaxResults")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "MaxResults", valid_604283
  var valid_604284 = query.getOrDefault("NextToken")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "NextToken", valid_604284
  var valid_604285 = query.getOrDefault("max-results")
  valid_604285 = validateParameter(valid_604285, JInt, required = false, default = nil)
  if valid_604285 != nil:
    section.add "max-results", valid_604285
  var valid_604286 = query.getOrDefault("next-token")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "next-token", valid_604286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604287 = header.getOrDefault("X-Amz-Signature")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Signature", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-Content-Sha256", valid_604288
  var valid_604289 = header.getOrDefault("X-Amz-Date")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "X-Amz-Date", valid_604289
  var valid_604290 = header.getOrDefault("X-Amz-Credential")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "X-Amz-Credential", valid_604290
  var valid_604291 = header.getOrDefault("X-Amz-Security-Token")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "X-Amz-Security-Token", valid_604291
  var valid_604292 = header.getOrDefault("X-Amz-Algorithm")
  valid_604292 = validateParameter(valid_604292, JString, required = false,
                                 default = nil)
  if valid_604292 != nil:
    section.add "X-Amz-Algorithm", valid_604292
  var valid_604293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604293 = validateParameter(valid_604293, JString, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "X-Amz-SignedHeaders", valid_604293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604294: Call_ListBots_604279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_604294.validator(path, query, header, formData, body)
  let scheme = call_604294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604294.url(scheme.get, call_604294.host, call_604294.base,
                         call_604294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604294, url, valid)

proc call*(call_604295: Call_ListBots_604279; accountId: string;
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
  var path_604296 = newJObject()
  var query_604297 = newJObject()
  add(query_604297, "MaxResults", newJString(MaxResults))
  add(query_604297, "NextToken", newJString(NextToken))
  add(query_604297, "max-results", newJInt(maxResults))
  add(path_604296, "accountId", newJString(accountId))
  add(query_604297, "next-token", newJString(nextToken))
  result = call_604295.call(path_604296, query_604297, nil, nil, nil)

var listBots* = Call_ListBots_604279(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_604280, base: "/",
                                  url: url_ListBots_604281,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMeeting_604331 = ref object of OpenApiRestCall_603389
proc url_CreateMeeting_604333(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMeeting_604332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604334 = header.getOrDefault("X-Amz-Signature")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Signature", valid_604334
  var valid_604335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Content-Sha256", valid_604335
  var valid_604336 = header.getOrDefault("X-Amz-Date")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "X-Amz-Date", valid_604336
  var valid_604337 = header.getOrDefault("X-Amz-Credential")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "X-Amz-Credential", valid_604337
  var valid_604338 = header.getOrDefault("X-Amz-Security-Token")
  valid_604338 = validateParameter(valid_604338, JString, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "X-Amz-Security-Token", valid_604338
  var valid_604339 = header.getOrDefault("X-Amz-Algorithm")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "X-Amz-Algorithm", valid_604339
  var valid_604340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "X-Amz-SignedHeaders", valid_604340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604342: Call_CreateMeeting_604331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604342.validator(path, query, header, formData, body)
  let scheme = call_604342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604342.url(scheme.get, call_604342.host, call_604342.base,
                         call_604342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604342, url, valid)

proc call*(call_604343: Call_CreateMeeting_604331; body: JsonNode): Recallable =
  ## createMeeting
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  var body_604344 = newJObject()
  if body != nil:
    body_604344 = body
  result = call_604343.call(nil, nil, nil, nil, body_604344)

var createMeeting* = Call_CreateMeeting_604331(name: "createMeeting",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_CreateMeeting_604332, base: "/", url: url_CreateMeeting_604333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeetings_604314 = ref object of OpenApiRestCall_603389
proc url_ListMeetings_604316(protocol: Scheme; host: string; base: string;
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

proc validate_ListMeetings_604315(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604317 = query.getOrDefault("MaxResults")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "MaxResults", valid_604317
  var valid_604318 = query.getOrDefault("NextToken")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "NextToken", valid_604318
  var valid_604319 = query.getOrDefault("max-results")
  valid_604319 = validateParameter(valid_604319, JInt, required = false, default = nil)
  if valid_604319 != nil:
    section.add "max-results", valid_604319
  var valid_604320 = query.getOrDefault("next-token")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "next-token", valid_604320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604321 = header.getOrDefault("X-Amz-Signature")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-Signature", valid_604321
  var valid_604322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "X-Amz-Content-Sha256", valid_604322
  var valid_604323 = header.getOrDefault("X-Amz-Date")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "X-Amz-Date", valid_604323
  var valid_604324 = header.getOrDefault("X-Amz-Credential")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Credential", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Security-Token")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Security-Token", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-Algorithm")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-Algorithm", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-SignedHeaders", valid_604327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604328: Call_ListMeetings_604314; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604328.validator(path, query, header, formData, body)
  let scheme = call_604328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604328.url(scheme.get, call_604328.host, call_604328.base,
                         call_604328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604328, url, valid)

proc call*(call_604329: Call_ListMeetings_604314; MaxResults: string = "";
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
  var query_604330 = newJObject()
  add(query_604330, "MaxResults", newJString(MaxResults))
  add(query_604330, "NextToken", newJString(NextToken))
  add(query_604330, "max-results", newJInt(maxResults))
  add(query_604330, "next-token", newJString(nextToken))
  result = call_604329.call(nil, query_604330, nil, nil, nil)

var listMeetings* = Call_ListMeetings_604314(name: "listMeetings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_ListMeetings_604315, base: "/", url: url_ListMeetings_604316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_604362 = ref object of OpenApiRestCall_603389
proc url_CreatePhoneNumberOrder_604364(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePhoneNumberOrder_604363(path: JsonNode; query: JsonNode;
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
  var valid_604365 = header.getOrDefault("X-Amz-Signature")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Signature", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-Content-Sha256", valid_604366
  var valid_604367 = header.getOrDefault("X-Amz-Date")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "X-Amz-Date", valid_604367
  var valid_604368 = header.getOrDefault("X-Amz-Credential")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "X-Amz-Credential", valid_604368
  var valid_604369 = header.getOrDefault("X-Amz-Security-Token")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Security-Token", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Algorithm")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Algorithm", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-SignedHeaders", valid_604371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604373: Call_CreatePhoneNumberOrder_604362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_604373.validator(path, query, header, formData, body)
  let scheme = call_604373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604373.url(scheme.get, call_604373.host, call_604373.base,
                         call_604373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604373, url, valid)

proc call*(call_604374: Call_CreatePhoneNumberOrder_604362; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_604375 = newJObject()
  if body != nil:
    body_604375 = body
  result = call_604374.call(nil, nil, nil, nil, body_604375)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_604362(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_604363, base: "/",
    url: url_CreatePhoneNumberOrder_604364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_604345 = ref object of OpenApiRestCall_603389
proc url_ListPhoneNumberOrders_604347(protocol: Scheme; host: string; base: string;
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

proc validate_ListPhoneNumberOrders_604346(path: JsonNode; query: JsonNode;
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
  var valid_604348 = query.getOrDefault("MaxResults")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "MaxResults", valid_604348
  var valid_604349 = query.getOrDefault("NextToken")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "NextToken", valid_604349
  var valid_604350 = query.getOrDefault("max-results")
  valid_604350 = validateParameter(valid_604350, JInt, required = false, default = nil)
  if valid_604350 != nil:
    section.add "max-results", valid_604350
  var valid_604351 = query.getOrDefault("next-token")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "next-token", valid_604351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604352 = header.getOrDefault("X-Amz-Signature")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "X-Amz-Signature", valid_604352
  var valid_604353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "X-Amz-Content-Sha256", valid_604353
  var valid_604354 = header.getOrDefault("X-Amz-Date")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Date", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Credential")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Credential", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Security-Token")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Security-Token", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Algorithm")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Algorithm", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-SignedHeaders", valid_604358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604359: Call_ListPhoneNumberOrders_604345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_604359.validator(path, query, header, formData, body)
  let scheme = call_604359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604359.url(scheme.get, call_604359.host, call_604359.base,
                         call_604359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604359, url, valid)

proc call*(call_604360: Call_ListPhoneNumberOrders_604345; MaxResults: string = "";
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
  var query_604361 = newJObject()
  add(query_604361, "MaxResults", newJString(MaxResults))
  add(query_604361, "NextToken", newJString(NextToken))
  add(query_604361, "max-results", newJInt(maxResults))
  add(query_604361, "next-token", newJString(nextToken))
  result = call_604360.call(nil, query_604361, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_604345(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_604346, base: "/",
    url: url_ListPhoneNumberOrders_604347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_604396 = ref object of OpenApiRestCall_603389
proc url_CreateRoom_604398(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateRoom_604397(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604399 = path.getOrDefault("accountId")
  valid_604399 = validateParameter(valid_604399, JString, required = true,
                                 default = nil)
  if valid_604399 != nil:
    section.add "accountId", valid_604399
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
  var valid_604400 = header.getOrDefault("X-Amz-Signature")
  valid_604400 = validateParameter(valid_604400, JString, required = false,
                                 default = nil)
  if valid_604400 != nil:
    section.add "X-Amz-Signature", valid_604400
  var valid_604401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-Content-Sha256", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Date")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Date", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Credential")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Credential", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-Security-Token")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Security-Token", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Algorithm")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Algorithm", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-SignedHeaders", valid_604406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604408: Call_CreateRoom_604396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a chat room for the specified Amazon Chime account.
  ## 
  let valid = call_604408.validator(path, query, header, formData, body)
  let scheme = call_604408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604408.url(scheme.get, call_604408.host, call_604408.base,
                         call_604408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604408, url, valid)

proc call*(call_604409: Call_CreateRoom_604396; body: JsonNode; accountId: string): Recallable =
  ## createRoom
  ## Creates a chat room for the specified Amazon Chime account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604410 = newJObject()
  var body_604411 = newJObject()
  if body != nil:
    body_604411 = body
  add(path_604410, "accountId", newJString(accountId))
  result = call_604409.call(path_604410, nil, nil, nil, body_604411)

var createRoom* = Call_CreateRoom_604396(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/rooms",
                                      validator: validate_CreateRoom_604397,
                                      base: "/", url: url_CreateRoom_604398,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRooms_604376 = ref object of OpenApiRestCall_603389
proc url_ListRooms_604378(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListRooms_604377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604379 = path.getOrDefault("accountId")
  valid_604379 = validateParameter(valid_604379, JString, required = true,
                                 default = nil)
  if valid_604379 != nil:
    section.add "accountId", valid_604379
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
  var valid_604380 = query.getOrDefault("member-id")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "member-id", valid_604380
  var valid_604381 = query.getOrDefault("MaxResults")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "MaxResults", valid_604381
  var valid_604382 = query.getOrDefault("NextToken")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "NextToken", valid_604382
  var valid_604383 = query.getOrDefault("max-results")
  valid_604383 = validateParameter(valid_604383, JInt, required = false, default = nil)
  if valid_604383 != nil:
    section.add "max-results", valid_604383
  var valid_604384 = query.getOrDefault("next-token")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "next-token", valid_604384
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604385 = header.getOrDefault("X-Amz-Signature")
  valid_604385 = validateParameter(valid_604385, JString, required = false,
                                 default = nil)
  if valid_604385 != nil:
    section.add "X-Amz-Signature", valid_604385
  var valid_604386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "X-Amz-Content-Sha256", valid_604386
  var valid_604387 = header.getOrDefault("X-Amz-Date")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Date", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Credential")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Credential", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-Security-Token")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-Security-Token", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Algorithm")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Algorithm", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-SignedHeaders", valid_604391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604392: Call_ListRooms_604376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the room details for the specified Amazon Chime account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  let valid = call_604392.validator(path, query, header, formData, body)
  let scheme = call_604392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604392.url(scheme.get, call_604392.host, call_604392.base,
                         call_604392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604392, url, valid)

proc call*(call_604393: Call_ListRooms_604376; accountId: string;
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
  var path_604394 = newJObject()
  var query_604395 = newJObject()
  add(query_604395, "member-id", newJString(memberId))
  add(query_604395, "MaxResults", newJString(MaxResults))
  add(query_604395, "NextToken", newJString(NextToken))
  add(query_604395, "max-results", newJInt(maxResults))
  add(path_604394, "accountId", newJString(accountId))
  add(query_604395, "next-token", newJString(nextToken))
  result = call_604393.call(path_604394, query_604395, nil, nil, nil)

var listRooms* = Call_ListRooms_604376(name: "listRooms", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/rooms",
                                    validator: validate_ListRooms_604377,
                                    base: "/", url: url_ListRooms_604378,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoomMembership_604432 = ref object of OpenApiRestCall_603389
proc url_CreateRoomMembership_604434(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoomMembership_604433(path: JsonNode; query: JsonNode;
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
  var valid_604435 = path.getOrDefault("accountId")
  valid_604435 = validateParameter(valid_604435, JString, required = true,
                                 default = nil)
  if valid_604435 != nil:
    section.add "accountId", valid_604435
  var valid_604436 = path.getOrDefault("roomId")
  valid_604436 = validateParameter(valid_604436, JString, required = true,
                                 default = nil)
  if valid_604436 != nil:
    section.add "roomId", valid_604436
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
  var valid_604437 = header.getOrDefault("X-Amz-Signature")
  valid_604437 = validateParameter(valid_604437, JString, required = false,
                                 default = nil)
  if valid_604437 != nil:
    section.add "X-Amz-Signature", valid_604437
  var valid_604438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-Content-Sha256", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-Date")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Date", valid_604439
  var valid_604440 = header.getOrDefault("X-Amz-Credential")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Credential", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-Security-Token")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Security-Token", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Algorithm")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Algorithm", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-SignedHeaders", valid_604443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604445: Call_CreateRoomMembership_604432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_604445.validator(path, query, header, formData, body)
  let scheme = call_604445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604445.url(scheme.get, call_604445.host, call_604445.base,
                         call_604445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604445, url, valid)

proc call*(call_604446: Call_CreateRoomMembership_604432; body: JsonNode;
          accountId: string; roomId: string): Recallable =
  ## createRoomMembership
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_604447 = newJObject()
  var body_604448 = newJObject()
  if body != nil:
    body_604448 = body
  add(path_604447, "accountId", newJString(accountId))
  add(path_604447, "roomId", newJString(roomId))
  result = call_604446.call(path_604447, nil, nil, nil, body_604448)

var createRoomMembership* = Call_CreateRoomMembership_604432(
    name: "createRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_CreateRoomMembership_604433, base: "/",
    url: url_CreateRoomMembership_604434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoomMemberships_604412 = ref object of OpenApiRestCall_603389
proc url_ListRoomMemberships_604414(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoomMemberships_604413(path: JsonNode; query: JsonNode;
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
  var valid_604415 = path.getOrDefault("accountId")
  valid_604415 = validateParameter(valid_604415, JString, required = true,
                                 default = nil)
  if valid_604415 != nil:
    section.add "accountId", valid_604415
  var valid_604416 = path.getOrDefault("roomId")
  valid_604416 = validateParameter(valid_604416, JString, required = true,
                                 default = nil)
  if valid_604416 != nil:
    section.add "roomId", valid_604416
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
  var valid_604417 = query.getOrDefault("MaxResults")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "MaxResults", valid_604417
  var valid_604418 = query.getOrDefault("NextToken")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "NextToken", valid_604418
  var valid_604419 = query.getOrDefault("max-results")
  valid_604419 = validateParameter(valid_604419, JInt, required = false, default = nil)
  if valid_604419 != nil:
    section.add "max-results", valid_604419
  var valid_604420 = query.getOrDefault("next-token")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "next-token", valid_604420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604421 = header.getOrDefault("X-Amz-Signature")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "X-Amz-Signature", valid_604421
  var valid_604422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "X-Amz-Content-Sha256", valid_604422
  var valid_604423 = header.getOrDefault("X-Amz-Date")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-Date", valid_604423
  var valid_604424 = header.getOrDefault("X-Amz-Credential")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-Credential", valid_604424
  var valid_604425 = header.getOrDefault("X-Amz-Security-Token")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Security-Token", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-Algorithm")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-Algorithm", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-SignedHeaders", valid_604427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604428: Call_ListRoomMemberships_604412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the membership details for the specified room, such as the members' IDs, email addresses, and names.
  ## 
  let valid = call_604428.validator(path, query, header, formData, body)
  let scheme = call_604428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604428.url(scheme.get, call_604428.host, call_604428.base,
                         call_604428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604428, url, valid)

proc call*(call_604429: Call_ListRoomMemberships_604412; accountId: string;
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
  var path_604430 = newJObject()
  var query_604431 = newJObject()
  add(query_604431, "MaxResults", newJString(MaxResults))
  add(query_604431, "NextToken", newJString(NextToken))
  add(query_604431, "max-results", newJInt(maxResults))
  add(path_604430, "accountId", newJString(accountId))
  add(path_604430, "roomId", newJString(roomId))
  add(query_604431, "next-token", newJString(nextToken))
  result = call_604429.call(path_604430, query_604431, nil, nil, nil)

var listRoomMemberships* = Call_ListRoomMemberships_604412(
    name: "listRoomMemberships", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_ListRoomMemberships_604413, base: "/",
    url: url_ListRoomMemberships_604414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_604449 = ref object of OpenApiRestCall_603389
proc url_CreateUser_604451(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_604450(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604452 = path.getOrDefault("accountId")
  valid_604452 = validateParameter(valid_604452, JString, required = true,
                                 default = nil)
  if valid_604452 != nil:
    section.add "accountId", valid_604452
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_604453 = query.getOrDefault("operation")
  valid_604453 = validateParameter(valid_604453, JString, required = true,
                                 default = newJString("create"))
  if valid_604453 != nil:
    section.add "operation", valid_604453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604454 = header.getOrDefault("X-Amz-Signature")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Signature", valid_604454
  var valid_604455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Content-Sha256", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-Date")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-Date", valid_604456
  var valid_604457 = header.getOrDefault("X-Amz-Credential")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "X-Amz-Credential", valid_604457
  var valid_604458 = header.getOrDefault("X-Amz-Security-Token")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Security-Token", valid_604458
  var valid_604459 = header.getOrDefault("X-Amz-Algorithm")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-Algorithm", valid_604459
  var valid_604460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "X-Amz-SignedHeaders", valid_604460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604462: Call_CreateUser_604449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user under the specified Amazon Chime account.
  ## 
  let valid = call_604462.validator(path, query, header, formData, body)
  let scheme = call_604462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604462.url(scheme.get, call_604462.host, call_604462.base,
                         call_604462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604462, url, valid)

proc call*(call_604463: Call_CreateUser_604449; body: JsonNode; accountId: string;
          operation: string = "create"): Recallable =
  ## createUser
  ## Creates a user under the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604464 = newJObject()
  var query_604465 = newJObject()
  var body_604466 = newJObject()
  add(query_604465, "operation", newJString(operation))
  if body != nil:
    body_604466 = body
  add(path_604464, "accountId", newJString(accountId))
  result = call_604463.call(path_604464, query_604465, nil, nil, body_604466)

var createUser* = Call_CreateUser_604449(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=create",
                                      validator: validate_CreateUser_604450,
                                      base: "/", url: url_CreateUser_604451,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_604484 = ref object of OpenApiRestCall_603389
proc url_CreateVoiceConnector_604486(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVoiceConnector_604485(path: JsonNode; query: JsonNode;
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
  var valid_604487 = header.getOrDefault("X-Amz-Signature")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "X-Amz-Signature", valid_604487
  var valid_604488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "X-Amz-Content-Sha256", valid_604488
  var valid_604489 = header.getOrDefault("X-Amz-Date")
  valid_604489 = validateParameter(valid_604489, JString, required = false,
                                 default = nil)
  if valid_604489 != nil:
    section.add "X-Amz-Date", valid_604489
  var valid_604490 = header.getOrDefault("X-Amz-Credential")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "X-Amz-Credential", valid_604490
  var valid_604491 = header.getOrDefault("X-Amz-Security-Token")
  valid_604491 = validateParameter(valid_604491, JString, required = false,
                                 default = nil)
  if valid_604491 != nil:
    section.add "X-Amz-Security-Token", valid_604491
  var valid_604492 = header.getOrDefault("X-Amz-Algorithm")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Algorithm", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-SignedHeaders", valid_604493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604495: Call_CreateVoiceConnector_604484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  let valid = call_604495.validator(path, query, header, formData, body)
  let scheme = call_604495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604495.url(scheme.get, call_604495.host, call_604495.base,
                         call_604495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604495, url, valid)

proc call*(call_604496: Call_CreateVoiceConnector_604484; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ##   body: JObject (required)
  var body_604497 = newJObject()
  if body != nil:
    body_604497 = body
  result = call_604496.call(nil, nil, nil, nil, body_604497)

var createVoiceConnector* = Call_CreateVoiceConnector_604484(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_604485, base: "/",
    url: url_CreateVoiceConnector_604486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_604467 = ref object of OpenApiRestCall_603389
proc url_ListVoiceConnectors_604469(protocol: Scheme; host: string; base: string;
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

proc validate_ListVoiceConnectors_604468(path: JsonNode; query: JsonNode;
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
  var valid_604470 = query.getOrDefault("MaxResults")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "MaxResults", valid_604470
  var valid_604471 = query.getOrDefault("NextToken")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "NextToken", valid_604471
  var valid_604472 = query.getOrDefault("max-results")
  valid_604472 = validateParameter(valid_604472, JInt, required = false, default = nil)
  if valid_604472 != nil:
    section.add "max-results", valid_604472
  var valid_604473 = query.getOrDefault("next-token")
  valid_604473 = validateParameter(valid_604473, JString, required = false,
                                 default = nil)
  if valid_604473 != nil:
    section.add "next-token", valid_604473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604474 = header.getOrDefault("X-Amz-Signature")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "X-Amz-Signature", valid_604474
  var valid_604475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604475 = validateParameter(valid_604475, JString, required = false,
                                 default = nil)
  if valid_604475 != nil:
    section.add "X-Amz-Content-Sha256", valid_604475
  var valid_604476 = header.getOrDefault("X-Amz-Date")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "X-Amz-Date", valid_604476
  var valid_604477 = header.getOrDefault("X-Amz-Credential")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Credential", valid_604477
  var valid_604478 = header.getOrDefault("X-Amz-Security-Token")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Security-Token", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-Algorithm")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-Algorithm", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-SignedHeaders", valid_604480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604481: Call_ListVoiceConnectors_604467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_604481.validator(path, query, header, formData, body)
  let scheme = call_604481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604481.url(scheme.get, call_604481.host, call_604481.base,
                         call_604481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604481, url, valid)

proc call*(call_604482: Call_ListVoiceConnectors_604467; MaxResults: string = "";
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
  var query_604483 = newJObject()
  add(query_604483, "MaxResults", newJString(MaxResults))
  add(query_604483, "NextToken", newJString(NextToken))
  add(query_604483, "max-results", newJInt(maxResults))
  add(query_604483, "next-token", newJString(nextToken))
  result = call_604482.call(nil, query_604483, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_604467(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_604468, base: "/",
    url: url_ListVoiceConnectors_604469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnectorGroup_604515 = ref object of OpenApiRestCall_603389
proc url_CreateVoiceConnectorGroup_604517(protocol: Scheme; host: string;
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

proc validate_CreateVoiceConnectorGroup_604516(path: JsonNode; query: JsonNode;
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
  var valid_604518 = header.getOrDefault("X-Amz-Signature")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-Signature", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-Content-Sha256", valid_604519
  var valid_604520 = header.getOrDefault("X-Amz-Date")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "X-Amz-Date", valid_604520
  var valid_604521 = header.getOrDefault("X-Amz-Credential")
  valid_604521 = validateParameter(valid_604521, JString, required = false,
                                 default = nil)
  if valid_604521 != nil:
    section.add "X-Amz-Credential", valid_604521
  var valid_604522 = header.getOrDefault("X-Amz-Security-Token")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "X-Amz-Security-Token", valid_604522
  var valid_604523 = header.getOrDefault("X-Amz-Algorithm")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "X-Amz-Algorithm", valid_604523
  var valid_604524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604524 = validateParameter(valid_604524, JString, required = false,
                                 default = nil)
  if valid_604524 != nil:
    section.add "X-Amz-SignedHeaders", valid_604524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604526: Call_CreateVoiceConnectorGroup_604515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  let valid = call_604526.validator(path, query, header, formData, body)
  let scheme = call_604526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604526.url(scheme.get, call_604526.host, call_604526.base,
                         call_604526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604526, url, valid)

proc call*(call_604527: Call_CreateVoiceConnectorGroup_604515; body: JsonNode): Recallable =
  ## createVoiceConnectorGroup
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ##   body: JObject (required)
  var body_604528 = newJObject()
  if body != nil:
    body_604528 = body
  result = call_604527.call(nil, nil, nil, nil, body_604528)

var createVoiceConnectorGroup* = Call_CreateVoiceConnectorGroup_604515(
    name: "createVoiceConnectorGroup", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_CreateVoiceConnectorGroup_604516, base: "/",
    url: url_CreateVoiceConnectorGroup_604517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorGroups_604498 = ref object of OpenApiRestCall_603389
proc url_ListVoiceConnectorGroups_604500(protocol: Scheme; host: string;
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

proc validate_ListVoiceConnectorGroups_604499(path: JsonNode; query: JsonNode;
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
  var valid_604501 = query.getOrDefault("MaxResults")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "MaxResults", valid_604501
  var valid_604502 = query.getOrDefault("NextToken")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "NextToken", valid_604502
  var valid_604503 = query.getOrDefault("max-results")
  valid_604503 = validateParameter(valid_604503, JInt, required = false, default = nil)
  if valid_604503 != nil:
    section.add "max-results", valid_604503
  var valid_604504 = query.getOrDefault("next-token")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "next-token", valid_604504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604505 = header.getOrDefault("X-Amz-Signature")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Signature", valid_604505
  var valid_604506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604506 = validateParameter(valid_604506, JString, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "X-Amz-Content-Sha256", valid_604506
  var valid_604507 = header.getOrDefault("X-Amz-Date")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Date", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-Credential")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Credential", valid_604508
  var valid_604509 = header.getOrDefault("X-Amz-Security-Token")
  valid_604509 = validateParameter(valid_604509, JString, required = false,
                                 default = nil)
  if valid_604509 != nil:
    section.add "X-Amz-Security-Token", valid_604509
  var valid_604510 = header.getOrDefault("X-Amz-Algorithm")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-Algorithm", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-SignedHeaders", valid_604511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604512: Call_ListVoiceConnectorGroups_604498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  let valid = call_604512.validator(path, query, header, formData, body)
  let scheme = call_604512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604512.url(scheme.get, call_604512.host, call_604512.base,
                         call_604512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604512, url, valid)

proc call*(call_604513: Call_ListVoiceConnectorGroups_604498;
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
  var query_604514 = newJObject()
  add(query_604514, "MaxResults", newJString(MaxResults))
  add(query_604514, "NextToken", newJString(NextToken))
  add(query_604514, "max-results", newJInt(maxResults))
  add(query_604514, "next-token", newJString(nextToken))
  result = call_604513.call(nil, query_604514, nil, nil, nil)

var listVoiceConnectorGroups* = Call_ListVoiceConnectorGroups_604498(
    name: "listVoiceConnectorGroups", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_ListVoiceConnectorGroups_604499, base: "/",
    url: url_ListVoiceConnectorGroups_604500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_604543 = ref object of OpenApiRestCall_603389
proc url_UpdateAccount_604545(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_604544(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604546 = path.getOrDefault("accountId")
  valid_604546 = validateParameter(valid_604546, JString, required = true,
                                 default = nil)
  if valid_604546 != nil:
    section.add "accountId", valid_604546
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
  var valid_604547 = header.getOrDefault("X-Amz-Signature")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "X-Amz-Signature", valid_604547
  var valid_604548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "X-Amz-Content-Sha256", valid_604548
  var valid_604549 = header.getOrDefault("X-Amz-Date")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "X-Amz-Date", valid_604549
  var valid_604550 = header.getOrDefault("X-Amz-Credential")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Credential", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-Security-Token")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-Security-Token", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-Algorithm")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Algorithm", valid_604552
  var valid_604553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "X-Amz-SignedHeaders", valid_604553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604555: Call_UpdateAccount_604543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_604555.validator(path, query, header, formData, body)
  let scheme = call_604555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604555.url(scheme.get, call_604555.host, call_604555.base,
                         call_604555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604555, url, valid)

proc call*(call_604556: Call_UpdateAccount_604543; body: JsonNode; accountId: string): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604557 = newJObject()
  var body_604558 = newJObject()
  if body != nil:
    body_604558 = body
  add(path_604557, "accountId", newJString(accountId))
  result = call_604556.call(path_604557, nil, nil, nil, body_604558)

var updateAccount* = Call_UpdateAccount_604543(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_604544,
    base: "/", url: url_UpdateAccount_604545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_604529 = ref object of OpenApiRestCall_603389
proc url_GetAccount_604531(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_604530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604532 = path.getOrDefault("accountId")
  valid_604532 = validateParameter(valid_604532, JString, required = true,
                                 default = nil)
  if valid_604532 != nil:
    section.add "accountId", valid_604532
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
  var valid_604533 = header.getOrDefault("X-Amz-Signature")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-Signature", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-Content-Sha256", valid_604534
  var valid_604535 = header.getOrDefault("X-Amz-Date")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Date", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-Credential")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-Credential", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-Security-Token")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Security-Token", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Algorithm")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Algorithm", valid_604538
  var valid_604539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604539 = validateParameter(valid_604539, JString, required = false,
                                 default = nil)
  if valid_604539 != nil:
    section.add "X-Amz-SignedHeaders", valid_604539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604540: Call_GetAccount_604529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_604540.validator(path, query, header, formData, body)
  let scheme = call_604540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604540.url(scheme.get, call_604540.host, call_604540.base,
                         call_604540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604540, url, valid)

proc call*(call_604541: Call_GetAccount_604529; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604542 = newJObject()
  add(path_604542, "accountId", newJString(accountId))
  result = call_604541.call(path_604542, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_604529(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_604530,
                                      base: "/", url: url_GetAccount_604531,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_604559 = ref object of OpenApiRestCall_603389
proc url_DeleteAccount_604561(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccount_604560(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604562 = path.getOrDefault("accountId")
  valid_604562 = validateParameter(valid_604562, JString, required = true,
                                 default = nil)
  if valid_604562 != nil:
    section.add "accountId", valid_604562
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
  var valid_604563 = header.getOrDefault("X-Amz-Signature")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "X-Amz-Signature", valid_604563
  var valid_604564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "X-Amz-Content-Sha256", valid_604564
  var valid_604565 = header.getOrDefault("X-Amz-Date")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "X-Amz-Date", valid_604565
  var valid_604566 = header.getOrDefault("X-Amz-Credential")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "X-Amz-Credential", valid_604566
  var valid_604567 = header.getOrDefault("X-Amz-Security-Token")
  valid_604567 = validateParameter(valid_604567, JString, required = false,
                                 default = nil)
  if valid_604567 != nil:
    section.add "X-Amz-Security-Token", valid_604567
  var valid_604568 = header.getOrDefault("X-Amz-Algorithm")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "X-Amz-Algorithm", valid_604568
  var valid_604569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604569 = validateParameter(valid_604569, JString, required = false,
                                 default = nil)
  if valid_604569 != nil:
    section.add "X-Amz-SignedHeaders", valid_604569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604570: Call_DeleteAccount_604559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_604570.validator(path, query, header, formData, body)
  let scheme = call_604570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604570.url(scheme.get, call_604570.host, call_604570.base,
                         call_604570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604570, url, valid)

proc call*(call_604571: Call_DeleteAccount_604559; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604572 = newJObject()
  add(path_604572, "accountId", newJString(accountId))
  result = call_604571.call(path_604572, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_604559(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_604560,
    base: "/", url: url_DeleteAccount_604561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttendee_604573 = ref object of OpenApiRestCall_603389
proc url_GetAttendee_604575(protocol: Scheme; host: string; base: string;
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

proc validate_GetAttendee_604574(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604576 = path.getOrDefault("attendeeId")
  valid_604576 = validateParameter(valid_604576, JString, required = true,
                                 default = nil)
  if valid_604576 != nil:
    section.add "attendeeId", valid_604576
  var valid_604577 = path.getOrDefault("meetingId")
  valid_604577 = validateParameter(valid_604577, JString, required = true,
                                 default = nil)
  if valid_604577 != nil:
    section.add "meetingId", valid_604577
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
  var valid_604578 = header.getOrDefault("X-Amz-Signature")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-Signature", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Content-Sha256", valid_604579
  var valid_604580 = header.getOrDefault("X-Amz-Date")
  valid_604580 = validateParameter(valid_604580, JString, required = false,
                                 default = nil)
  if valid_604580 != nil:
    section.add "X-Amz-Date", valid_604580
  var valid_604581 = header.getOrDefault("X-Amz-Credential")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-Credential", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Security-Token")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Security-Token", valid_604582
  var valid_604583 = header.getOrDefault("X-Amz-Algorithm")
  valid_604583 = validateParameter(valid_604583, JString, required = false,
                                 default = nil)
  if valid_604583 != nil:
    section.add "X-Amz-Algorithm", valid_604583
  var valid_604584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-SignedHeaders", valid_604584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604585: Call_GetAttendee_604573; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604585.validator(path, query, header, formData, body)
  let scheme = call_604585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604585.url(scheme.get, call_604585.host, call_604585.base,
                         call_604585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604585, url, valid)

proc call*(call_604586: Call_GetAttendee_604573; attendeeId: string;
          meetingId: string): Recallable =
  ## getAttendee
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_604587 = newJObject()
  add(path_604587, "attendeeId", newJString(attendeeId))
  add(path_604587, "meetingId", newJString(meetingId))
  result = call_604586.call(path_604587, nil, nil, nil, nil)

var getAttendee* = Call_GetAttendee_604573(name: "getAttendee",
                                        meth: HttpMethod.HttpGet,
                                        host: "chime.amazonaws.com", route: "/meetings/{meetingId}/attendees/{attendeeId}",
                                        validator: validate_GetAttendee_604574,
                                        base: "/", url: url_GetAttendee_604575,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttendee_604588 = ref object of OpenApiRestCall_603389
proc url_DeleteAttendee_604590(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAttendee_604589(path: JsonNode; query: JsonNode;
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
  var valid_604591 = path.getOrDefault("attendeeId")
  valid_604591 = validateParameter(valid_604591, JString, required = true,
                                 default = nil)
  if valid_604591 != nil:
    section.add "attendeeId", valid_604591
  var valid_604592 = path.getOrDefault("meetingId")
  valid_604592 = validateParameter(valid_604592, JString, required = true,
                                 default = nil)
  if valid_604592 != nil:
    section.add "meetingId", valid_604592
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
  var valid_604593 = header.getOrDefault("X-Amz-Signature")
  valid_604593 = validateParameter(valid_604593, JString, required = false,
                                 default = nil)
  if valid_604593 != nil:
    section.add "X-Amz-Signature", valid_604593
  var valid_604594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "X-Amz-Content-Sha256", valid_604594
  var valid_604595 = header.getOrDefault("X-Amz-Date")
  valid_604595 = validateParameter(valid_604595, JString, required = false,
                                 default = nil)
  if valid_604595 != nil:
    section.add "X-Amz-Date", valid_604595
  var valid_604596 = header.getOrDefault("X-Amz-Credential")
  valid_604596 = validateParameter(valid_604596, JString, required = false,
                                 default = nil)
  if valid_604596 != nil:
    section.add "X-Amz-Credential", valid_604596
  var valid_604597 = header.getOrDefault("X-Amz-Security-Token")
  valid_604597 = validateParameter(valid_604597, JString, required = false,
                                 default = nil)
  if valid_604597 != nil:
    section.add "X-Amz-Security-Token", valid_604597
  var valid_604598 = header.getOrDefault("X-Amz-Algorithm")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "X-Amz-Algorithm", valid_604598
  var valid_604599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "X-Amz-SignedHeaders", valid_604599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604600: Call_DeleteAttendee_604588; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604600.validator(path, query, header, formData, body)
  let scheme = call_604600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604600.url(scheme.get, call_604600.host, call_604600.base,
                         call_604600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604600, url, valid)

proc call*(call_604601: Call_DeleteAttendee_604588; attendeeId: string;
          meetingId: string): Recallable =
  ## deleteAttendee
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_604602 = newJObject()
  add(path_604602, "attendeeId", newJString(attendeeId))
  add(path_604602, "meetingId", newJString(meetingId))
  result = call_604601.call(path_604602, nil, nil, nil, nil)

var deleteAttendee* = Call_DeleteAttendee_604588(name: "deleteAttendee",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees/{attendeeId}",
    validator: validate_DeleteAttendee_604589, base: "/", url: url_DeleteAttendee_604590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_604618 = ref object of OpenApiRestCall_603389
proc url_PutEventsConfiguration_604620(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventsConfiguration_604619(path: JsonNode; query: JsonNode;
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
  var valid_604621 = path.getOrDefault("botId")
  valid_604621 = validateParameter(valid_604621, JString, required = true,
                                 default = nil)
  if valid_604621 != nil:
    section.add "botId", valid_604621
  var valid_604622 = path.getOrDefault("accountId")
  valid_604622 = validateParameter(valid_604622, JString, required = true,
                                 default = nil)
  if valid_604622 != nil:
    section.add "accountId", valid_604622
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
  var valid_604623 = header.getOrDefault("X-Amz-Signature")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Signature", valid_604623
  var valid_604624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "X-Amz-Content-Sha256", valid_604624
  var valid_604625 = header.getOrDefault("X-Amz-Date")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "X-Amz-Date", valid_604625
  var valid_604626 = header.getOrDefault("X-Amz-Credential")
  valid_604626 = validateParameter(valid_604626, JString, required = false,
                                 default = nil)
  if valid_604626 != nil:
    section.add "X-Amz-Credential", valid_604626
  var valid_604627 = header.getOrDefault("X-Amz-Security-Token")
  valid_604627 = validateParameter(valid_604627, JString, required = false,
                                 default = nil)
  if valid_604627 != nil:
    section.add "X-Amz-Security-Token", valid_604627
  var valid_604628 = header.getOrDefault("X-Amz-Algorithm")
  valid_604628 = validateParameter(valid_604628, JString, required = false,
                                 default = nil)
  if valid_604628 != nil:
    section.add "X-Amz-Algorithm", valid_604628
  var valid_604629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604629 = validateParameter(valid_604629, JString, required = false,
                                 default = nil)
  if valid_604629 != nil:
    section.add "X-Amz-SignedHeaders", valid_604629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604631: Call_PutEventsConfiguration_604618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_604631.validator(path, query, header, formData, body)
  let scheme = call_604631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604631.url(scheme.get, call_604631.host, call_604631.base,
                         call_604631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604631, url, valid)

proc call*(call_604632: Call_PutEventsConfiguration_604618; botId: string;
          body: JsonNode; accountId: string): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604633 = newJObject()
  var body_604634 = newJObject()
  add(path_604633, "botId", newJString(botId))
  if body != nil:
    body_604634 = body
  add(path_604633, "accountId", newJString(accountId))
  result = call_604632.call(path_604633, nil, nil, nil, body_604634)

var putEventsConfiguration* = Call_PutEventsConfiguration_604618(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_604619, base: "/",
    url: url_PutEventsConfiguration_604620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_604603 = ref object of OpenApiRestCall_603389
proc url_GetEventsConfiguration_604605(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventsConfiguration_604604(path: JsonNode; query: JsonNode;
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
  var valid_604606 = path.getOrDefault("botId")
  valid_604606 = validateParameter(valid_604606, JString, required = true,
                                 default = nil)
  if valid_604606 != nil:
    section.add "botId", valid_604606
  var valid_604607 = path.getOrDefault("accountId")
  valid_604607 = validateParameter(valid_604607, JString, required = true,
                                 default = nil)
  if valid_604607 != nil:
    section.add "accountId", valid_604607
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
  var valid_604608 = header.getOrDefault("X-Amz-Signature")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "X-Amz-Signature", valid_604608
  var valid_604609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604609 = validateParameter(valid_604609, JString, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "X-Amz-Content-Sha256", valid_604609
  var valid_604610 = header.getOrDefault("X-Amz-Date")
  valid_604610 = validateParameter(valid_604610, JString, required = false,
                                 default = nil)
  if valid_604610 != nil:
    section.add "X-Amz-Date", valid_604610
  var valid_604611 = header.getOrDefault("X-Amz-Credential")
  valid_604611 = validateParameter(valid_604611, JString, required = false,
                                 default = nil)
  if valid_604611 != nil:
    section.add "X-Amz-Credential", valid_604611
  var valid_604612 = header.getOrDefault("X-Amz-Security-Token")
  valid_604612 = validateParameter(valid_604612, JString, required = false,
                                 default = nil)
  if valid_604612 != nil:
    section.add "X-Amz-Security-Token", valid_604612
  var valid_604613 = header.getOrDefault("X-Amz-Algorithm")
  valid_604613 = validateParameter(valid_604613, JString, required = false,
                                 default = nil)
  if valid_604613 != nil:
    section.add "X-Amz-Algorithm", valid_604613
  var valid_604614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "X-Amz-SignedHeaders", valid_604614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604615: Call_GetEventsConfiguration_604603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_604615.validator(path, query, header, formData, body)
  let scheme = call_604615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604615.url(scheme.get, call_604615.host, call_604615.base,
                         call_604615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604615, url, valid)

proc call*(call_604616: Call_GetEventsConfiguration_604603; botId: string;
          accountId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604617 = newJObject()
  add(path_604617, "botId", newJString(botId))
  add(path_604617, "accountId", newJString(accountId))
  result = call_604616.call(path_604617, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_604603(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_604604, base: "/",
    url: url_GetEventsConfiguration_604605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_604635 = ref object of OpenApiRestCall_603389
proc url_DeleteEventsConfiguration_604637(protocol: Scheme; host: string;
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

proc validate_DeleteEventsConfiguration_604636(path: JsonNode; query: JsonNode;
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
  var valid_604638 = path.getOrDefault("botId")
  valid_604638 = validateParameter(valid_604638, JString, required = true,
                                 default = nil)
  if valid_604638 != nil:
    section.add "botId", valid_604638
  var valid_604639 = path.getOrDefault("accountId")
  valid_604639 = validateParameter(valid_604639, JString, required = true,
                                 default = nil)
  if valid_604639 != nil:
    section.add "accountId", valid_604639
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
  var valid_604640 = header.getOrDefault("X-Amz-Signature")
  valid_604640 = validateParameter(valid_604640, JString, required = false,
                                 default = nil)
  if valid_604640 != nil:
    section.add "X-Amz-Signature", valid_604640
  var valid_604641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "X-Amz-Content-Sha256", valid_604641
  var valid_604642 = header.getOrDefault("X-Amz-Date")
  valid_604642 = validateParameter(valid_604642, JString, required = false,
                                 default = nil)
  if valid_604642 != nil:
    section.add "X-Amz-Date", valid_604642
  var valid_604643 = header.getOrDefault("X-Amz-Credential")
  valid_604643 = validateParameter(valid_604643, JString, required = false,
                                 default = nil)
  if valid_604643 != nil:
    section.add "X-Amz-Credential", valid_604643
  var valid_604644 = header.getOrDefault("X-Amz-Security-Token")
  valid_604644 = validateParameter(valid_604644, JString, required = false,
                                 default = nil)
  if valid_604644 != nil:
    section.add "X-Amz-Security-Token", valid_604644
  var valid_604645 = header.getOrDefault("X-Amz-Algorithm")
  valid_604645 = validateParameter(valid_604645, JString, required = false,
                                 default = nil)
  if valid_604645 != nil:
    section.add "X-Amz-Algorithm", valid_604645
  var valid_604646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "X-Amz-SignedHeaders", valid_604646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604647: Call_DeleteEventsConfiguration_604635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_604647.validator(path, query, header, formData, body)
  let scheme = call_604647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604647.url(scheme.get, call_604647.host, call_604647.base,
                         call_604647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604647, url, valid)

proc call*(call_604648: Call_DeleteEventsConfiguration_604635; botId: string;
          accountId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_604649 = newJObject()
  add(path_604649, "botId", newJString(botId))
  add(path_604649, "accountId", newJString(accountId))
  result = call_604648.call(path_604649, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_604635(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_604636, base: "/",
    url: url_DeleteEventsConfiguration_604637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMeeting_604650 = ref object of OpenApiRestCall_603389
proc url_GetMeeting_604652(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMeeting_604651(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604653 = path.getOrDefault("meetingId")
  valid_604653 = validateParameter(valid_604653, JString, required = true,
                                 default = nil)
  if valid_604653 != nil:
    section.add "meetingId", valid_604653
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
  var valid_604654 = header.getOrDefault("X-Amz-Signature")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "X-Amz-Signature", valid_604654
  var valid_604655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "X-Amz-Content-Sha256", valid_604655
  var valid_604656 = header.getOrDefault("X-Amz-Date")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "X-Amz-Date", valid_604656
  var valid_604657 = header.getOrDefault("X-Amz-Credential")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "X-Amz-Credential", valid_604657
  var valid_604658 = header.getOrDefault("X-Amz-Security-Token")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "X-Amz-Security-Token", valid_604658
  var valid_604659 = header.getOrDefault("X-Amz-Algorithm")
  valid_604659 = validateParameter(valid_604659, JString, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "X-Amz-Algorithm", valid_604659
  var valid_604660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-SignedHeaders", valid_604660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604661: Call_GetMeeting_604650; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604661.validator(path, query, header, formData, body)
  let scheme = call_604661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604661.url(scheme.get, call_604661.host, call_604661.base,
                         call_604661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604661, url, valid)

proc call*(call_604662: Call_GetMeeting_604650; meetingId: string): Recallable =
  ## getMeeting
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_604663 = newJObject()
  add(path_604663, "meetingId", newJString(meetingId))
  result = call_604662.call(path_604663, nil, nil, nil, nil)

var getMeeting* = Call_GetMeeting_604650(name: "getMeeting",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/meetings/{meetingId}",
                                      validator: validate_GetMeeting_604651,
                                      base: "/", url: url_GetMeeting_604652,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMeeting_604664 = ref object of OpenApiRestCall_603389
proc url_DeleteMeeting_604666(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMeeting_604665(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604667 = path.getOrDefault("meetingId")
  valid_604667 = validateParameter(valid_604667, JString, required = true,
                                 default = nil)
  if valid_604667 != nil:
    section.add "meetingId", valid_604667
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
  var valid_604668 = header.getOrDefault("X-Amz-Signature")
  valid_604668 = validateParameter(valid_604668, JString, required = false,
                                 default = nil)
  if valid_604668 != nil:
    section.add "X-Amz-Signature", valid_604668
  var valid_604669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604669 = validateParameter(valid_604669, JString, required = false,
                                 default = nil)
  if valid_604669 != nil:
    section.add "X-Amz-Content-Sha256", valid_604669
  var valid_604670 = header.getOrDefault("X-Amz-Date")
  valid_604670 = validateParameter(valid_604670, JString, required = false,
                                 default = nil)
  if valid_604670 != nil:
    section.add "X-Amz-Date", valid_604670
  var valid_604671 = header.getOrDefault("X-Amz-Credential")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "X-Amz-Credential", valid_604671
  var valid_604672 = header.getOrDefault("X-Amz-Security-Token")
  valid_604672 = validateParameter(valid_604672, JString, required = false,
                                 default = nil)
  if valid_604672 != nil:
    section.add "X-Amz-Security-Token", valid_604672
  var valid_604673 = header.getOrDefault("X-Amz-Algorithm")
  valid_604673 = validateParameter(valid_604673, JString, required = false,
                                 default = nil)
  if valid_604673 != nil:
    section.add "X-Amz-Algorithm", valid_604673
  var valid_604674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604674 = validateParameter(valid_604674, JString, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "X-Amz-SignedHeaders", valid_604674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604675: Call_DeleteMeeting_604664; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_604675.validator(path, query, header, formData, body)
  let scheme = call_604675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604675.url(scheme.get, call_604675.host, call_604675.base,
                         call_604675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604675, url, valid)

proc call*(call_604676: Call_DeleteMeeting_604664; meetingId: string): Recallable =
  ## deleteMeeting
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_604677 = newJObject()
  add(path_604677, "meetingId", newJString(meetingId))
  result = call_604676.call(path_604677, nil, nil, nil, nil)

var deleteMeeting* = Call_DeleteMeeting_604664(name: "deleteMeeting",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}", validator: validate_DeleteMeeting_604665,
    base: "/", url: url_DeleteMeeting_604666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_604692 = ref object of OpenApiRestCall_603389
proc url_UpdatePhoneNumber_604694(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePhoneNumber_604693(path: JsonNode; query: JsonNode;
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
  var valid_604695 = path.getOrDefault("phoneNumberId")
  valid_604695 = validateParameter(valid_604695, JString, required = true,
                                 default = nil)
  if valid_604695 != nil:
    section.add "phoneNumberId", valid_604695
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
  var valid_604696 = header.getOrDefault("X-Amz-Signature")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-Signature", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-Content-Sha256", valid_604697
  var valid_604698 = header.getOrDefault("X-Amz-Date")
  valid_604698 = validateParameter(valid_604698, JString, required = false,
                                 default = nil)
  if valid_604698 != nil:
    section.add "X-Amz-Date", valid_604698
  var valid_604699 = header.getOrDefault("X-Amz-Credential")
  valid_604699 = validateParameter(valid_604699, JString, required = false,
                                 default = nil)
  if valid_604699 != nil:
    section.add "X-Amz-Credential", valid_604699
  var valid_604700 = header.getOrDefault("X-Amz-Security-Token")
  valid_604700 = validateParameter(valid_604700, JString, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "X-Amz-Security-Token", valid_604700
  var valid_604701 = header.getOrDefault("X-Amz-Algorithm")
  valid_604701 = validateParameter(valid_604701, JString, required = false,
                                 default = nil)
  if valid_604701 != nil:
    section.add "X-Amz-Algorithm", valid_604701
  var valid_604702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604702 = validateParameter(valid_604702, JString, required = false,
                                 default = nil)
  if valid_604702 != nil:
    section.add "X-Amz-SignedHeaders", valid_604702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604704: Call_UpdatePhoneNumber_604692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_604704.validator(path, query, header, formData, body)
  let scheme = call_604704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604704.url(scheme.get, call_604704.host, call_604704.base,
                         call_604704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604704, url, valid)

proc call*(call_604705: Call_UpdatePhoneNumber_604692; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_604706 = newJObject()
  var body_604707 = newJObject()
  add(path_604706, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_604707 = body
  result = call_604705.call(path_604706, nil, nil, nil, body_604707)

var updatePhoneNumber* = Call_UpdatePhoneNumber_604692(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_604693, base: "/",
    url: url_UpdatePhoneNumber_604694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_604678 = ref object of OpenApiRestCall_603389
proc url_GetPhoneNumber_604680(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumber_604679(path: JsonNode; query: JsonNode;
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
  var valid_604681 = path.getOrDefault("phoneNumberId")
  valid_604681 = validateParameter(valid_604681, JString, required = true,
                                 default = nil)
  if valid_604681 != nil:
    section.add "phoneNumberId", valid_604681
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
  var valid_604682 = header.getOrDefault("X-Amz-Signature")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "X-Amz-Signature", valid_604682
  var valid_604683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604683 = validateParameter(valid_604683, JString, required = false,
                                 default = nil)
  if valid_604683 != nil:
    section.add "X-Amz-Content-Sha256", valid_604683
  var valid_604684 = header.getOrDefault("X-Amz-Date")
  valid_604684 = validateParameter(valid_604684, JString, required = false,
                                 default = nil)
  if valid_604684 != nil:
    section.add "X-Amz-Date", valid_604684
  var valid_604685 = header.getOrDefault("X-Amz-Credential")
  valid_604685 = validateParameter(valid_604685, JString, required = false,
                                 default = nil)
  if valid_604685 != nil:
    section.add "X-Amz-Credential", valid_604685
  var valid_604686 = header.getOrDefault("X-Amz-Security-Token")
  valid_604686 = validateParameter(valid_604686, JString, required = false,
                                 default = nil)
  if valid_604686 != nil:
    section.add "X-Amz-Security-Token", valid_604686
  var valid_604687 = header.getOrDefault("X-Amz-Algorithm")
  valid_604687 = validateParameter(valid_604687, JString, required = false,
                                 default = nil)
  if valid_604687 != nil:
    section.add "X-Amz-Algorithm", valid_604687
  var valid_604688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604688 = validateParameter(valid_604688, JString, required = false,
                                 default = nil)
  if valid_604688 != nil:
    section.add "X-Amz-SignedHeaders", valid_604688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604689: Call_GetPhoneNumber_604678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_604689.validator(path, query, header, formData, body)
  let scheme = call_604689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604689.url(scheme.get, call_604689.host, call_604689.base,
                         call_604689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604689, url, valid)

proc call*(call_604690: Call_GetPhoneNumber_604678; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_604691 = newJObject()
  add(path_604691, "phoneNumberId", newJString(phoneNumberId))
  result = call_604690.call(path_604691, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_604678(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_604679,
    base: "/", url: url_GetPhoneNumber_604680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_604708 = ref object of OpenApiRestCall_603389
proc url_DeletePhoneNumber_604710(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePhoneNumber_604709(path: JsonNode; query: JsonNode;
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
  var valid_604711 = path.getOrDefault("phoneNumberId")
  valid_604711 = validateParameter(valid_604711, JString, required = true,
                                 default = nil)
  if valid_604711 != nil:
    section.add "phoneNumberId", valid_604711
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
  var valid_604712 = header.getOrDefault("X-Amz-Signature")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Signature", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-Content-Sha256", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-Date")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-Date", valid_604714
  var valid_604715 = header.getOrDefault("X-Amz-Credential")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-Credential", valid_604715
  var valid_604716 = header.getOrDefault("X-Amz-Security-Token")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "X-Amz-Security-Token", valid_604716
  var valid_604717 = header.getOrDefault("X-Amz-Algorithm")
  valid_604717 = validateParameter(valid_604717, JString, required = false,
                                 default = nil)
  if valid_604717 != nil:
    section.add "X-Amz-Algorithm", valid_604717
  var valid_604718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604718 = validateParameter(valid_604718, JString, required = false,
                                 default = nil)
  if valid_604718 != nil:
    section.add "X-Amz-SignedHeaders", valid_604718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604719: Call_DeletePhoneNumber_604708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_604719.validator(path, query, header, formData, body)
  let scheme = call_604719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604719.url(scheme.get, call_604719.host, call_604719.base,
                         call_604719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604719, url, valid)

proc call*(call_604720: Call_DeletePhoneNumber_604708; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_604721 = newJObject()
  add(path_604721, "phoneNumberId", newJString(phoneNumberId))
  result = call_604720.call(path_604721, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_604708(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_604709, base: "/",
    url: url_DeletePhoneNumber_604710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_604737 = ref object of OpenApiRestCall_603389
proc url_UpdateRoom_604739(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateRoom_604738(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604740 = path.getOrDefault("accountId")
  valid_604740 = validateParameter(valid_604740, JString, required = true,
                                 default = nil)
  if valid_604740 != nil:
    section.add "accountId", valid_604740
  var valid_604741 = path.getOrDefault("roomId")
  valid_604741 = validateParameter(valid_604741, JString, required = true,
                                 default = nil)
  if valid_604741 != nil:
    section.add "roomId", valid_604741
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
  var valid_604742 = header.getOrDefault("X-Amz-Signature")
  valid_604742 = validateParameter(valid_604742, JString, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "X-Amz-Signature", valid_604742
  var valid_604743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604743 = validateParameter(valid_604743, JString, required = false,
                                 default = nil)
  if valid_604743 != nil:
    section.add "X-Amz-Content-Sha256", valid_604743
  var valid_604744 = header.getOrDefault("X-Amz-Date")
  valid_604744 = validateParameter(valid_604744, JString, required = false,
                                 default = nil)
  if valid_604744 != nil:
    section.add "X-Amz-Date", valid_604744
  var valid_604745 = header.getOrDefault("X-Amz-Credential")
  valid_604745 = validateParameter(valid_604745, JString, required = false,
                                 default = nil)
  if valid_604745 != nil:
    section.add "X-Amz-Credential", valid_604745
  var valid_604746 = header.getOrDefault("X-Amz-Security-Token")
  valid_604746 = validateParameter(valid_604746, JString, required = false,
                                 default = nil)
  if valid_604746 != nil:
    section.add "X-Amz-Security-Token", valid_604746
  var valid_604747 = header.getOrDefault("X-Amz-Algorithm")
  valid_604747 = validateParameter(valid_604747, JString, required = false,
                                 default = nil)
  if valid_604747 != nil:
    section.add "X-Amz-Algorithm", valid_604747
  var valid_604748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604748 = validateParameter(valid_604748, JString, required = false,
                                 default = nil)
  if valid_604748 != nil:
    section.add "X-Amz-SignedHeaders", valid_604748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604750: Call_UpdateRoom_604737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details, such as the room name.
  ## 
  let valid = call_604750.validator(path, query, header, formData, body)
  let scheme = call_604750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604750.url(scheme.get, call_604750.host, call_604750.base,
                         call_604750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604750, url, valid)

proc call*(call_604751: Call_UpdateRoom_604737; body: JsonNode; accountId: string;
          roomId: string): Recallable =
  ## updateRoom
  ## Updates room details, such as the room name.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_604752 = newJObject()
  var body_604753 = newJObject()
  if body != nil:
    body_604753 = body
  add(path_604752, "accountId", newJString(accountId))
  add(path_604752, "roomId", newJString(roomId))
  result = call_604751.call(path_604752, nil, nil, nil, body_604753)

var updateRoom* = Call_UpdateRoom_604737(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_UpdateRoom_604738,
                                      base: "/", url: url_UpdateRoom_604739,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_604722 = ref object of OpenApiRestCall_603389
proc url_GetRoom_604724(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoom_604723(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604725 = path.getOrDefault("accountId")
  valid_604725 = validateParameter(valid_604725, JString, required = true,
                                 default = nil)
  if valid_604725 != nil:
    section.add "accountId", valid_604725
  var valid_604726 = path.getOrDefault("roomId")
  valid_604726 = validateParameter(valid_604726, JString, required = true,
                                 default = nil)
  if valid_604726 != nil:
    section.add "roomId", valid_604726
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
  var valid_604727 = header.getOrDefault("X-Amz-Signature")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Signature", valid_604727
  var valid_604728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604728 = validateParameter(valid_604728, JString, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "X-Amz-Content-Sha256", valid_604728
  var valid_604729 = header.getOrDefault("X-Amz-Date")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "X-Amz-Date", valid_604729
  var valid_604730 = header.getOrDefault("X-Amz-Credential")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "X-Amz-Credential", valid_604730
  var valid_604731 = header.getOrDefault("X-Amz-Security-Token")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "X-Amz-Security-Token", valid_604731
  var valid_604732 = header.getOrDefault("X-Amz-Algorithm")
  valid_604732 = validateParameter(valid_604732, JString, required = false,
                                 default = nil)
  if valid_604732 != nil:
    section.add "X-Amz-Algorithm", valid_604732
  var valid_604733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604733 = validateParameter(valid_604733, JString, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "X-Amz-SignedHeaders", valid_604733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604734: Call_GetRoom_604722; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves room details, such as the room name.
  ## 
  let valid = call_604734.validator(path, query, header, formData, body)
  let scheme = call_604734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604734.url(scheme.get, call_604734.host, call_604734.base,
                         call_604734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604734, url, valid)

proc call*(call_604735: Call_GetRoom_604722; accountId: string; roomId: string): Recallable =
  ## getRoom
  ## Retrieves room details, such as the room name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_604736 = newJObject()
  add(path_604736, "accountId", newJString(accountId))
  add(path_604736, "roomId", newJString(roomId))
  result = call_604735.call(path_604736, nil, nil, nil, nil)

var getRoom* = Call_GetRoom_604722(name: "getRoom", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/rooms/{roomId}",
                                validator: validate_GetRoom_604723, base: "/",
                                url: url_GetRoom_604724,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_604754 = ref object of OpenApiRestCall_603389
proc url_DeleteRoom_604756(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteRoom_604755(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604757 = path.getOrDefault("accountId")
  valid_604757 = validateParameter(valid_604757, JString, required = true,
                                 default = nil)
  if valid_604757 != nil:
    section.add "accountId", valid_604757
  var valid_604758 = path.getOrDefault("roomId")
  valid_604758 = validateParameter(valid_604758, JString, required = true,
                                 default = nil)
  if valid_604758 != nil:
    section.add "roomId", valid_604758
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
  var valid_604759 = header.getOrDefault("X-Amz-Signature")
  valid_604759 = validateParameter(valid_604759, JString, required = false,
                                 default = nil)
  if valid_604759 != nil:
    section.add "X-Amz-Signature", valid_604759
  var valid_604760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604760 = validateParameter(valid_604760, JString, required = false,
                                 default = nil)
  if valid_604760 != nil:
    section.add "X-Amz-Content-Sha256", valid_604760
  var valid_604761 = header.getOrDefault("X-Amz-Date")
  valid_604761 = validateParameter(valid_604761, JString, required = false,
                                 default = nil)
  if valid_604761 != nil:
    section.add "X-Amz-Date", valid_604761
  var valid_604762 = header.getOrDefault("X-Amz-Credential")
  valid_604762 = validateParameter(valid_604762, JString, required = false,
                                 default = nil)
  if valid_604762 != nil:
    section.add "X-Amz-Credential", valid_604762
  var valid_604763 = header.getOrDefault("X-Amz-Security-Token")
  valid_604763 = validateParameter(valid_604763, JString, required = false,
                                 default = nil)
  if valid_604763 != nil:
    section.add "X-Amz-Security-Token", valid_604763
  var valid_604764 = header.getOrDefault("X-Amz-Algorithm")
  valid_604764 = validateParameter(valid_604764, JString, required = false,
                                 default = nil)
  if valid_604764 != nil:
    section.add "X-Amz-Algorithm", valid_604764
  var valid_604765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-SignedHeaders", valid_604765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604766: Call_DeleteRoom_604754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a chat room.
  ## 
  let valid = call_604766.validator(path, query, header, formData, body)
  let scheme = call_604766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604766.url(scheme.get, call_604766.host, call_604766.base,
                         call_604766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604766, url, valid)

proc call*(call_604767: Call_DeleteRoom_604754; accountId: string; roomId: string): Recallable =
  ## deleteRoom
  ## Deletes a chat room.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The chat room ID.
  var path_604768 = newJObject()
  add(path_604768, "accountId", newJString(accountId))
  add(path_604768, "roomId", newJString(roomId))
  result = call_604767.call(path_604768, nil, nil, nil, nil)

var deleteRoom* = Call_DeleteRoom_604754(name: "deleteRoom",
                                      meth: HttpMethod.HttpDelete,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_DeleteRoom_604755,
                                      base: "/", url: url_DeleteRoom_604756,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoomMembership_604769 = ref object of OpenApiRestCall_603389
proc url_UpdateRoomMembership_604771(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoomMembership_604770(path: JsonNode; query: JsonNode;
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
  var valid_604772 = path.getOrDefault("memberId")
  valid_604772 = validateParameter(valid_604772, JString, required = true,
                                 default = nil)
  if valid_604772 != nil:
    section.add "memberId", valid_604772
  var valid_604773 = path.getOrDefault("accountId")
  valid_604773 = validateParameter(valid_604773, JString, required = true,
                                 default = nil)
  if valid_604773 != nil:
    section.add "accountId", valid_604773
  var valid_604774 = path.getOrDefault("roomId")
  valid_604774 = validateParameter(valid_604774, JString, required = true,
                                 default = nil)
  if valid_604774 != nil:
    section.add "roomId", valid_604774
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
  var valid_604775 = header.getOrDefault("X-Amz-Signature")
  valid_604775 = validateParameter(valid_604775, JString, required = false,
                                 default = nil)
  if valid_604775 != nil:
    section.add "X-Amz-Signature", valid_604775
  var valid_604776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604776 = validateParameter(valid_604776, JString, required = false,
                                 default = nil)
  if valid_604776 != nil:
    section.add "X-Amz-Content-Sha256", valid_604776
  var valid_604777 = header.getOrDefault("X-Amz-Date")
  valid_604777 = validateParameter(valid_604777, JString, required = false,
                                 default = nil)
  if valid_604777 != nil:
    section.add "X-Amz-Date", valid_604777
  var valid_604778 = header.getOrDefault("X-Amz-Credential")
  valid_604778 = validateParameter(valid_604778, JString, required = false,
                                 default = nil)
  if valid_604778 != nil:
    section.add "X-Amz-Credential", valid_604778
  var valid_604779 = header.getOrDefault("X-Amz-Security-Token")
  valid_604779 = validateParameter(valid_604779, JString, required = false,
                                 default = nil)
  if valid_604779 != nil:
    section.add "X-Amz-Security-Token", valid_604779
  var valid_604780 = header.getOrDefault("X-Amz-Algorithm")
  valid_604780 = validateParameter(valid_604780, JString, required = false,
                                 default = nil)
  if valid_604780 != nil:
    section.add "X-Amz-Algorithm", valid_604780
  var valid_604781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604781 = validateParameter(valid_604781, JString, required = false,
                                 default = nil)
  if valid_604781 != nil:
    section.add "X-Amz-SignedHeaders", valid_604781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604783: Call_UpdateRoomMembership_604769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room membership details, such as the member role. The member role designates whether the member is a chat room administrator or a general chat room member. The member role can be updated only for user IDs.
  ## 
  let valid = call_604783.validator(path, query, header, formData, body)
  let scheme = call_604783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604783.url(scheme.get, call_604783.host, call_604783.base,
                         call_604783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604783, url, valid)

proc call*(call_604784: Call_UpdateRoomMembership_604769; memberId: string;
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
  var path_604785 = newJObject()
  var body_604786 = newJObject()
  add(path_604785, "memberId", newJString(memberId))
  if body != nil:
    body_604786 = body
  add(path_604785, "accountId", newJString(accountId))
  add(path_604785, "roomId", newJString(roomId))
  result = call_604784.call(path_604785, nil, nil, nil, body_604786)

var updateRoomMembership* = Call_UpdateRoomMembership_604769(
    name: "updateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_UpdateRoomMembership_604770, base: "/",
    url: url_UpdateRoomMembership_604771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomMembership_604787 = ref object of OpenApiRestCall_603389
proc url_DeleteRoomMembership_604789(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoomMembership_604788(path: JsonNode; query: JsonNode;
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
  var valid_604790 = path.getOrDefault("memberId")
  valid_604790 = validateParameter(valid_604790, JString, required = true,
                                 default = nil)
  if valid_604790 != nil:
    section.add "memberId", valid_604790
  var valid_604791 = path.getOrDefault("accountId")
  valid_604791 = validateParameter(valid_604791, JString, required = true,
                                 default = nil)
  if valid_604791 != nil:
    section.add "accountId", valid_604791
  var valid_604792 = path.getOrDefault("roomId")
  valid_604792 = validateParameter(valid_604792, JString, required = true,
                                 default = nil)
  if valid_604792 != nil:
    section.add "roomId", valid_604792
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
  var valid_604793 = header.getOrDefault("X-Amz-Signature")
  valid_604793 = validateParameter(valid_604793, JString, required = false,
                                 default = nil)
  if valid_604793 != nil:
    section.add "X-Amz-Signature", valid_604793
  var valid_604794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604794 = validateParameter(valid_604794, JString, required = false,
                                 default = nil)
  if valid_604794 != nil:
    section.add "X-Amz-Content-Sha256", valid_604794
  var valid_604795 = header.getOrDefault("X-Amz-Date")
  valid_604795 = validateParameter(valid_604795, JString, required = false,
                                 default = nil)
  if valid_604795 != nil:
    section.add "X-Amz-Date", valid_604795
  var valid_604796 = header.getOrDefault("X-Amz-Credential")
  valid_604796 = validateParameter(valid_604796, JString, required = false,
                                 default = nil)
  if valid_604796 != nil:
    section.add "X-Amz-Credential", valid_604796
  var valid_604797 = header.getOrDefault("X-Amz-Security-Token")
  valid_604797 = validateParameter(valid_604797, JString, required = false,
                                 default = nil)
  if valid_604797 != nil:
    section.add "X-Amz-Security-Token", valid_604797
  var valid_604798 = header.getOrDefault("X-Amz-Algorithm")
  valid_604798 = validateParameter(valid_604798, JString, required = false,
                                 default = nil)
  if valid_604798 != nil:
    section.add "X-Amz-Algorithm", valid_604798
  var valid_604799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604799 = validateParameter(valid_604799, JString, required = false,
                                 default = nil)
  if valid_604799 != nil:
    section.add "X-Amz-SignedHeaders", valid_604799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604800: Call_DeleteRoomMembership_604787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a member from a chat room.
  ## 
  let valid = call_604800.validator(path, query, header, formData, body)
  let scheme = call_604800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604800.url(scheme.get, call_604800.host, call_604800.base,
                         call_604800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604800, url, valid)

proc call*(call_604801: Call_DeleteRoomMembership_604787; memberId: string;
          accountId: string; roomId: string): Recallable =
  ## deleteRoomMembership
  ## Removes a member from a chat room.
  ##   memberId: string (required)
  ##           : The member ID (user ID or bot ID).
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_604802 = newJObject()
  add(path_604802, "memberId", newJString(memberId))
  add(path_604802, "accountId", newJString(accountId))
  add(path_604802, "roomId", newJString(roomId))
  result = call_604801.call(path_604802, nil, nil, nil, nil)

var deleteRoomMembership* = Call_DeleteRoomMembership_604787(
    name: "deleteRoomMembership", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_DeleteRoomMembership_604788, base: "/",
    url: url_DeleteRoomMembership_604789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_604817 = ref object of OpenApiRestCall_603389
proc url_UpdateVoiceConnector_604819(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceConnector_604818(path: JsonNode; query: JsonNode;
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
  var valid_604820 = path.getOrDefault("voiceConnectorId")
  valid_604820 = validateParameter(valid_604820, JString, required = true,
                                 default = nil)
  if valid_604820 != nil:
    section.add "voiceConnectorId", valid_604820
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
  var valid_604821 = header.getOrDefault("X-Amz-Signature")
  valid_604821 = validateParameter(valid_604821, JString, required = false,
                                 default = nil)
  if valid_604821 != nil:
    section.add "X-Amz-Signature", valid_604821
  var valid_604822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604822 = validateParameter(valid_604822, JString, required = false,
                                 default = nil)
  if valid_604822 != nil:
    section.add "X-Amz-Content-Sha256", valid_604822
  var valid_604823 = header.getOrDefault("X-Amz-Date")
  valid_604823 = validateParameter(valid_604823, JString, required = false,
                                 default = nil)
  if valid_604823 != nil:
    section.add "X-Amz-Date", valid_604823
  var valid_604824 = header.getOrDefault("X-Amz-Credential")
  valid_604824 = validateParameter(valid_604824, JString, required = false,
                                 default = nil)
  if valid_604824 != nil:
    section.add "X-Amz-Credential", valid_604824
  var valid_604825 = header.getOrDefault("X-Amz-Security-Token")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Security-Token", valid_604825
  var valid_604826 = header.getOrDefault("X-Amz-Algorithm")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "X-Amz-Algorithm", valid_604826
  var valid_604827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604827 = validateParameter(valid_604827, JString, required = false,
                                 default = nil)
  if valid_604827 != nil:
    section.add "X-Amz-SignedHeaders", valid_604827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604829: Call_UpdateVoiceConnector_604817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_604829.validator(path, query, header, formData, body)
  let scheme = call_604829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604829.url(scheme.get, call_604829.host, call_604829.base,
                         call_604829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604829, url, valid)

proc call*(call_604830: Call_UpdateVoiceConnector_604817; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_604831 = newJObject()
  var body_604832 = newJObject()
  add(path_604831, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_604832 = body
  result = call_604830.call(path_604831, nil, nil, nil, body_604832)

var updateVoiceConnector* = Call_UpdateVoiceConnector_604817(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_604818, base: "/",
    url: url_UpdateVoiceConnector_604819, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_604803 = ref object of OpenApiRestCall_603389
proc url_GetVoiceConnector_604805(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnector_604804(path: JsonNode; query: JsonNode;
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
  var valid_604806 = path.getOrDefault("voiceConnectorId")
  valid_604806 = validateParameter(valid_604806, JString, required = true,
                                 default = nil)
  if valid_604806 != nil:
    section.add "voiceConnectorId", valid_604806
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
  var valid_604807 = header.getOrDefault("X-Amz-Signature")
  valid_604807 = validateParameter(valid_604807, JString, required = false,
                                 default = nil)
  if valid_604807 != nil:
    section.add "X-Amz-Signature", valid_604807
  var valid_604808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604808 = validateParameter(valid_604808, JString, required = false,
                                 default = nil)
  if valid_604808 != nil:
    section.add "X-Amz-Content-Sha256", valid_604808
  var valid_604809 = header.getOrDefault("X-Amz-Date")
  valid_604809 = validateParameter(valid_604809, JString, required = false,
                                 default = nil)
  if valid_604809 != nil:
    section.add "X-Amz-Date", valid_604809
  var valid_604810 = header.getOrDefault("X-Amz-Credential")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Credential", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Security-Token")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Security-Token", valid_604811
  var valid_604812 = header.getOrDefault("X-Amz-Algorithm")
  valid_604812 = validateParameter(valid_604812, JString, required = false,
                                 default = nil)
  if valid_604812 != nil:
    section.add "X-Amz-Algorithm", valid_604812
  var valid_604813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-SignedHeaders", valid_604813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604814: Call_GetVoiceConnector_604803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_604814.validator(path, query, header, formData, body)
  let scheme = call_604814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604814.url(scheme.get, call_604814.host, call_604814.base,
                         call_604814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604814, url, valid)

proc call*(call_604815: Call_GetVoiceConnector_604803; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_604816 = newJObject()
  add(path_604816, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_604815.call(path_604816, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_604803(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_604804, base: "/",
    url: url_GetVoiceConnector_604805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_604833 = ref object of OpenApiRestCall_603389
proc url_DeleteVoiceConnector_604835(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceConnector_604834(path: JsonNode; query: JsonNode;
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
  var valid_604836 = path.getOrDefault("voiceConnectorId")
  valid_604836 = validateParameter(valid_604836, JString, required = true,
                                 default = nil)
  if valid_604836 != nil:
    section.add "voiceConnectorId", valid_604836
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
  var valid_604837 = header.getOrDefault("X-Amz-Signature")
  valid_604837 = validateParameter(valid_604837, JString, required = false,
                                 default = nil)
  if valid_604837 != nil:
    section.add "X-Amz-Signature", valid_604837
  var valid_604838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604838 = validateParameter(valid_604838, JString, required = false,
                                 default = nil)
  if valid_604838 != nil:
    section.add "X-Amz-Content-Sha256", valid_604838
  var valid_604839 = header.getOrDefault("X-Amz-Date")
  valid_604839 = validateParameter(valid_604839, JString, required = false,
                                 default = nil)
  if valid_604839 != nil:
    section.add "X-Amz-Date", valid_604839
  var valid_604840 = header.getOrDefault("X-Amz-Credential")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Credential", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Security-Token")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Security-Token", valid_604841
  var valid_604842 = header.getOrDefault("X-Amz-Algorithm")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-Algorithm", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-SignedHeaders", valid_604843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604844: Call_DeleteVoiceConnector_604833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  let valid = call_604844.validator(path, query, header, formData, body)
  let scheme = call_604844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604844.url(scheme.get, call_604844.host, call_604844.base,
                         call_604844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604844, url, valid)

proc call*(call_604845: Call_DeleteVoiceConnector_604833; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_604846 = newJObject()
  add(path_604846, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_604845.call(path_604846, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_604833(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_604834, base: "/",
    url: url_DeleteVoiceConnector_604835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnectorGroup_604861 = ref object of OpenApiRestCall_603389
proc url_UpdateVoiceConnectorGroup_604863(protocol: Scheme; host: string;
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

proc validate_UpdateVoiceConnectorGroup_604862(path: JsonNode; query: JsonNode;
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
  var valid_604864 = path.getOrDefault("voiceConnectorGroupId")
  valid_604864 = validateParameter(valid_604864, JString, required = true,
                                 default = nil)
  if valid_604864 != nil:
    section.add "voiceConnectorGroupId", valid_604864
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
  var valid_604865 = header.getOrDefault("X-Amz-Signature")
  valid_604865 = validateParameter(valid_604865, JString, required = false,
                                 default = nil)
  if valid_604865 != nil:
    section.add "X-Amz-Signature", valid_604865
  var valid_604866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604866 = validateParameter(valid_604866, JString, required = false,
                                 default = nil)
  if valid_604866 != nil:
    section.add "X-Amz-Content-Sha256", valid_604866
  var valid_604867 = header.getOrDefault("X-Amz-Date")
  valid_604867 = validateParameter(valid_604867, JString, required = false,
                                 default = nil)
  if valid_604867 != nil:
    section.add "X-Amz-Date", valid_604867
  var valid_604868 = header.getOrDefault("X-Amz-Credential")
  valid_604868 = validateParameter(valid_604868, JString, required = false,
                                 default = nil)
  if valid_604868 != nil:
    section.add "X-Amz-Credential", valid_604868
  var valid_604869 = header.getOrDefault("X-Amz-Security-Token")
  valid_604869 = validateParameter(valid_604869, JString, required = false,
                                 default = nil)
  if valid_604869 != nil:
    section.add "X-Amz-Security-Token", valid_604869
  var valid_604870 = header.getOrDefault("X-Amz-Algorithm")
  valid_604870 = validateParameter(valid_604870, JString, required = false,
                                 default = nil)
  if valid_604870 != nil:
    section.add "X-Amz-Algorithm", valid_604870
  var valid_604871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604871 = validateParameter(valid_604871, JString, required = false,
                                 default = nil)
  if valid_604871 != nil:
    section.add "X-Amz-SignedHeaders", valid_604871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604873: Call_UpdateVoiceConnectorGroup_604861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  let valid = call_604873.validator(path, query, header, formData, body)
  let scheme = call_604873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604873.url(scheme.get, call_604873.host, call_604873.base,
                         call_604873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604873, url, valid)

proc call*(call_604874: Call_UpdateVoiceConnectorGroup_604861;
          voiceConnectorGroupId: string; body: JsonNode): Recallable =
  ## updateVoiceConnectorGroup
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   body: JObject (required)
  var path_604875 = newJObject()
  var body_604876 = newJObject()
  add(path_604875, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  if body != nil:
    body_604876 = body
  result = call_604874.call(path_604875, nil, nil, nil, body_604876)

var updateVoiceConnectorGroup* = Call_UpdateVoiceConnectorGroup_604861(
    name: "updateVoiceConnectorGroup", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_UpdateVoiceConnectorGroup_604862, base: "/",
    url: url_UpdateVoiceConnectorGroup_604863,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorGroup_604847 = ref object of OpenApiRestCall_603389
proc url_GetVoiceConnectorGroup_604849(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnectorGroup_604848(path: JsonNode; query: JsonNode;
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
  var valid_604850 = path.getOrDefault("voiceConnectorGroupId")
  valid_604850 = validateParameter(valid_604850, JString, required = true,
                                 default = nil)
  if valid_604850 != nil:
    section.add "voiceConnectorGroupId", valid_604850
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
  var valid_604851 = header.getOrDefault("X-Amz-Signature")
  valid_604851 = validateParameter(valid_604851, JString, required = false,
                                 default = nil)
  if valid_604851 != nil:
    section.add "X-Amz-Signature", valid_604851
  var valid_604852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604852 = validateParameter(valid_604852, JString, required = false,
                                 default = nil)
  if valid_604852 != nil:
    section.add "X-Amz-Content-Sha256", valid_604852
  var valid_604853 = header.getOrDefault("X-Amz-Date")
  valid_604853 = validateParameter(valid_604853, JString, required = false,
                                 default = nil)
  if valid_604853 != nil:
    section.add "X-Amz-Date", valid_604853
  var valid_604854 = header.getOrDefault("X-Amz-Credential")
  valid_604854 = validateParameter(valid_604854, JString, required = false,
                                 default = nil)
  if valid_604854 != nil:
    section.add "X-Amz-Credential", valid_604854
  var valid_604855 = header.getOrDefault("X-Amz-Security-Token")
  valid_604855 = validateParameter(valid_604855, JString, required = false,
                                 default = nil)
  if valid_604855 != nil:
    section.add "X-Amz-Security-Token", valid_604855
  var valid_604856 = header.getOrDefault("X-Amz-Algorithm")
  valid_604856 = validateParameter(valid_604856, JString, required = false,
                                 default = nil)
  if valid_604856 != nil:
    section.add "X-Amz-Algorithm", valid_604856
  var valid_604857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "X-Amz-SignedHeaders", valid_604857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604858: Call_GetVoiceConnectorGroup_604847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  let valid = call_604858.validator(path, query, header, formData, body)
  let scheme = call_604858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604858.url(scheme.get, call_604858.host, call_604858.base,
                         call_604858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604858, url, valid)

proc call*(call_604859: Call_GetVoiceConnectorGroup_604847;
          voiceConnectorGroupId: string): Recallable =
  ## getVoiceConnectorGroup
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_604860 = newJObject()
  add(path_604860, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_604859.call(path_604860, nil, nil, nil, nil)

var getVoiceConnectorGroup* = Call_GetVoiceConnectorGroup_604847(
    name: "getVoiceConnectorGroup", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_GetVoiceConnectorGroup_604848, base: "/",
    url: url_GetVoiceConnectorGroup_604849, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorGroup_604877 = ref object of OpenApiRestCall_603389
proc url_DeleteVoiceConnectorGroup_604879(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorGroup_604878(path: JsonNode; query: JsonNode;
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
  var valid_604880 = path.getOrDefault("voiceConnectorGroupId")
  valid_604880 = validateParameter(valid_604880, JString, required = true,
                                 default = nil)
  if valid_604880 != nil:
    section.add "voiceConnectorGroupId", valid_604880
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
  var valid_604881 = header.getOrDefault("X-Amz-Signature")
  valid_604881 = validateParameter(valid_604881, JString, required = false,
                                 default = nil)
  if valid_604881 != nil:
    section.add "X-Amz-Signature", valid_604881
  var valid_604882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604882 = validateParameter(valid_604882, JString, required = false,
                                 default = nil)
  if valid_604882 != nil:
    section.add "X-Amz-Content-Sha256", valid_604882
  var valid_604883 = header.getOrDefault("X-Amz-Date")
  valid_604883 = validateParameter(valid_604883, JString, required = false,
                                 default = nil)
  if valid_604883 != nil:
    section.add "X-Amz-Date", valid_604883
  var valid_604884 = header.getOrDefault("X-Amz-Credential")
  valid_604884 = validateParameter(valid_604884, JString, required = false,
                                 default = nil)
  if valid_604884 != nil:
    section.add "X-Amz-Credential", valid_604884
  var valid_604885 = header.getOrDefault("X-Amz-Security-Token")
  valid_604885 = validateParameter(valid_604885, JString, required = false,
                                 default = nil)
  if valid_604885 != nil:
    section.add "X-Amz-Security-Token", valid_604885
  var valid_604886 = header.getOrDefault("X-Amz-Algorithm")
  valid_604886 = validateParameter(valid_604886, JString, required = false,
                                 default = nil)
  if valid_604886 != nil:
    section.add "X-Amz-Algorithm", valid_604886
  var valid_604887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604887 = validateParameter(valid_604887, JString, required = false,
                                 default = nil)
  if valid_604887 != nil:
    section.add "X-Amz-SignedHeaders", valid_604887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604888: Call_DeleteVoiceConnectorGroup_604877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  let valid = call_604888.validator(path, query, header, formData, body)
  let scheme = call_604888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604888.url(scheme.get, call_604888.host, call_604888.base,
                         call_604888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604888, url, valid)

proc call*(call_604889: Call_DeleteVoiceConnectorGroup_604877;
          voiceConnectorGroupId: string): Recallable =
  ## deleteVoiceConnectorGroup
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_604890 = newJObject()
  add(path_604890, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_604889.call(path_604890, nil, nil, nil, nil)

var deleteVoiceConnectorGroup* = Call_DeleteVoiceConnectorGroup_604877(
    name: "deleteVoiceConnectorGroup", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_DeleteVoiceConnectorGroup_604878, base: "/",
    url: url_DeleteVoiceConnectorGroup_604879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_604905 = ref object of OpenApiRestCall_603389
proc url_PutVoiceConnectorOrigination_604907(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorOrigination_604906(path: JsonNode; query: JsonNode;
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
  var valid_604908 = path.getOrDefault("voiceConnectorId")
  valid_604908 = validateParameter(valid_604908, JString, required = true,
                                 default = nil)
  if valid_604908 != nil:
    section.add "voiceConnectorId", valid_604908
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
  var valid_604909 = header.getOrDefault("X-Amz-Signature")
  valid_604909 = validateParameter(valid_604909, JString, required = false,
                                 default = nil)
  if valid_604909 != nil:
    section.add "X-Amz-Signature", valid_604909
  var valid_604910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604910 = validateParameter(valid_604910, JString, required = false,
                                 default = nil)
  if valid_604910 != nil:
    section.add "X-Amz-Content-Sha256", valid_604910
  var valid_604911 = header.getOrDefault("X-Amz-Date")
  valid_604911 = validateParameter(valid_604911, JString, required = false,
                                 default = nil)
  if valid_604911 != nil:
    section.add "X-Amz-Date", valid_604911
  var valid_604912 = header.getOrDefault("X-Amz-Credential")
  valid_604912 = validateParameter(valid_604912, JString, required = false,
                                 default = nil)
  if valid_604912 != nil:
    section.add "X-Amz-Credential", valid_604912
  var valid_604913 = header.getOrDefault("X-Amz-Security-Token")
  valid_604913 = validateParameter(valid_604913, JString, required = false,
                                 default = nil)
  if valid_604913 != nil:
    section.add "X-Amz-Security-Token", valid_604913
  var valid_604914 = header.getOrDefault("X-Amz-Algorithm")
  valid_604914 = validateParameter(valid_604914, JString, required = false,
                                 default = nil)
  if valid_604914 != nil:
    section.add "X-Amz-Algorithm", valid_604914
  var valid_604915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604915 = validateParameter(valid_604915, JString, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "X-Amz-SignedHeaders", valid_604915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604917: Call_PutVoiceConnectorOrigination_604905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_604917.validator(path, query, header, formData, body)
  let scheme = call_604917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604917.url(scheme.get, call_604917.host, call_604917.base,
                         call_604917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604917, url, valid)

proc call*(call_604918: Call_PutVoiceConnectorOrigination_604905;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_604919 = newJObject()
  var body_604920 = newJObject()
  add(path_604919, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_604920 = body
  result = call_604918.call(path_604919, nil, nil, nil, body_604920)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_604905(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_604906, base: "/",
    url: url_PutVoiceConnectorOrigination_604907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_604891 = ref object of OpenApiRestCall_603389
proc url_GetVoiceConnectorOrigination_604893(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorOrigination_604892(path: JsonNode; query: JsonNode;
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
  var valid_604894 = path.getOrDefault("voiceConnectorId")
  valid_604894 = validateParameter(valid_604894, JString, required = true,
                                 default = nil)
  if valid_604894 != nil:
    section.add "voiceConnectorId", valid_604894
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
  var valid_604895 = header.getOrDefault("X-Amz-Signature")
  valid_604895 = validateParameter(valid_604895, JString, required = false,
                                 default = nil)
  if valid_604895 != nil:
    section.add "X-Amz-Signature", valid_604895
  var valid_604896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604896 = validateParameter(valid_604896, JString, required = false,
                                 default = nil)
  if valid_604896 != nil:
    section.add "X-Amz-Content-Sha256", valid_604896
  var valid_604897 = header.getOrDefault("X-Amz-Date")
  valid_604897 = validateParameter(valid_604897, JString, required = false,
                                 default = nil)
  if valid_604897 != nil:
    section.add "X-Amz-Date", valid_604897
  var valid_604898 = header.getOrDefault("X-Amz-Credential")
  valid_604898 = validateParameter(valid_604898, JString, required = false,
                                 default = nil)
  if valid_604898 != nil:
    section.add "X-Amz-Credential", valid_604898
  var valid_604899 = header.getOrDefault("X-Amz-Security-Token")
  valid_604899 = validateParameter(valid_604899, JString, required = false,
                                 default = nil)
  if valid_604899 != nil:
    section.add "X-Amz-Security-Token", valid_604899
  var valid_604900 = header.getOrDefault("X-Amz-Algorithm")
  valid_604900 = validateParameter(valid_604900, JString, required = false,
                                 default = nil)
  if valid_604900 != nil:
    section.add "X-Amz-Algorithm", valid_604900
  var valid_604901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604901 = validateParameter(valid_604901, JString, required = false,
                                 default = nil)
  if valid_604901 != nil:
    section.add "X-Amz-SignedHeaders", valid_604901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604902: Call_GetVoiceConnectorOrigination_604891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_604902.validator(path, query, header, formData, body)
  let scheme = call_604902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604902.url(scheme.get, call_604902.host, call_604902.base,
                         call_604902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604902, url, valid)

proc call*(call_604903: Call_GetVoiceConnectorOrigination_604891;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_604904 = newJObject()
  add(path_604904, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_604903.call(path_604904, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_604891(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_604892, base: "/",
    url: url_GetVoiceConnectorOrigination_604893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_604921 = ref object of OpenApiRestCall_603389
proc url_DeleteVoiceConnectorOrigination_604923(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorOrigination_604922(path: JsonNode;
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
  var valid_604924 = path.getOrDefault("voiceConnectorId")
  valid_604924 = validateParameter(valid_604924, JString, required = true,
                                 default = nil)
  if valid_604924 != nil:
    section.add "voiceConnectorId", valid_604924
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
  var valid_604925 = header.getOrDefault("X-Amz-Signature")
  valid_604925 = validateParameter(valid_604925, JString, required = false,
                                 default = nil)
  if valid_604925 != nil:
    section.add "X-Amz-Signature", valid_604925
  var valid_604926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604926 = validateParameter(valid_604926, JString, required = false,
                                 default = nil)
  if valid_604926 != nil:
    section.add "X-Amz-Content-Sha256", valid_604926
  var valid_604927 = header.getOrDefault("X-Amz-Date")
  valid_604927 = validateParameter(valid_604927, JString, required = false,
                                 default = nil)
  if valid_604927 != nil:
    section.add "X-Amz-Date", valid_604927
  var valid_604928 = header.getOrDefault("X-Amz-Credential")
  valid_604928 = validateParameter(valid_604928, JString, required = false,
                                 default = nil)
  if valid_604928 != nil:
    section.add "X-Amz-Credential", valid_604928
  var valid_604929 = header.getOrDefault("X-Amz-Security-Token")
  valid_604929 = validateParameter(valid_604929, JString, required = false,
                                 default = nil)
  if valid_604929 != nil:
    section.add "X-Amz-Security-Token", valid_604929
  var valid_604930 = header.getOrDefault("X-Amz-Algorithm")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-Algorithm", valid_604930
  var valid_604931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-SignedHeaders", valid_604931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604932: Call_DeleteVoiceConnectorOrigination_604921;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_604932.validator(path, query, header, formData, body)
  let scheme = call_604932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604932.url(scheme.get, call_604932.host, call_604932.base,
                         call_604932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604932, url, valid)

proc call*(call_604933: Call_DeleteVoiceConnectorOrigination_604921;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_604934 = newJObject()
  add(path_604934, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_604933.call(path_604934, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_604921(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_604922, base: "/",
    url: url_DeleteVoiceConnectorOrigination_604923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorStreamingConfiguration_604949 = ref object of OpenApiRestCall_603389
proc url_PutVoiceConnectorStreamingConfiguration_604951(protocol: Scheme;
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

proc validate_PutVoiceConnectorStreamingConfiguration_604950(path: JsonNode;
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
  var valid_604952 = path.getOrDefault("voiceConnectorId")
  valid_604952 = validateParameter(valid_604952, JString, required = true,
                                 default = nil)
  if valid_604952 != nil:
    section.add "voiceConnectorId", valid_604952
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
  var valid_604953 = header.getOrDefault("X-Amz-Signature")
  valid_604953 = validateParameter(valid_604953, JString, required = false,
                                 default = nil)
  if valid_604953 != nil:
    section.add "X-Amz-Signature", valid_604953
  var valid_604954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604954 = validateParameter(valid_604954, JString, required = false,
                                 default = nil)
  if valid_604954 != nil:
    section.add "X-Amz-Content-Sha256", valid_604954
  var valid_604955 = header.getOrDefault("X-Amz-Date")
  valid_604955 = validateParameter(valid_604955, JString, required = false,
                                 default = nil)
  if valid_604955 != nil:
    section.add "X-Amz-Date", valid_604955
  var valid_604956 = header.getOrDefault("X-Amz-Credential")
  valid_604956 = validateParameter(valid_604956, JString, required = false,
                                 default = nil)
  if valid_604956 != nil:
    section.add "X-Amz-Credential", valid_604956
  var valid_604957 = header.getOrDefault("X-Amz-Security-Token")
  valid_604957 = validateParameter(valid_604957, JString, required = false,
                                 default = nil)
  if valid_604957 != nil:
    section.add "X-Amz-Security-Token", valid_604957
  var valid_604958 = header.getOrDefault("X-Amz-Algorithm")
  valid_604958 = validateParameter(valid_604958, JString, required = false,
                                 default = nil)
  if valid_604958 != nil:
    section.add "X-Amz-Algorithm", valid_604958
  var valid_604959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604959 = validateParameter(valid_604959, JString, required = false,
                                 default = nil)
  if valid_604959 != nil:
    section.add "X-Amz-SignedHeaders", valid_604959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604961: Call_PutVoiceConnectorStreamingConfiguration_604949;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_604961.validator(path, query, header, formData, body)
  let scheme = call_604961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604961.url(scheme.get, call_604961.host, call_604961.base,
                         call_604961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604961, url, valid)

proc call*(call_604962: Call_PutVoiceConnectorStreamingConfiguration_604949;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorStreamingConfiguration
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_604963 = newJObject()
  var body_604964 = newJObject()
  add(path_604963, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_604964 = body
  result = call_604962.call(path_604963, nil, nil, nil, body_604964)

var putVoiceConnectorStreamingConfiguration* = Call_PutVoiceConnectorStreamingConfiguration_604949(
    name: "putVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_PutVoiceConnectorStreamingConfiguration_604950, base: "/",
    url: url_PutVoiceConnectorStreamingConfiguration_604951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorStreamingConfiguration_604935 = ref object of OpenApiRestCall_603389
proc url_GetVoiceConnectorStreamingConfiguration_604937(protocol: Scheme;
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

proc validate_GetVoiceConnectorStreamingConfiguration_604936(path: JsonNode;
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
  var valid_604938 = path.getOrDefault("voiceConnectorId")
  valid_604938 = validateParameter(valid_604938, JString, required = true,
                                 default = nil)
  if valid_604938 != nil:
    section.add "voiceConnectorId", valid_604938
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
  var valid_604939 = header.getOrDefault("X-Amz-Signature")
  valid_604939 = validateParameter(valid_604939, JString, required = false,
                                 default = nil)
  if valid_604939 != nil:
    section.add "X-Amz-Signature", valid_604939
  var valid_604940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604940 = validateParameter(valid_604940, JString, required = false,
                                 default = nil)
  if valid_604940 != nil:
    section.add "X-Amz-Content-Sha256", valid_604940
  var valid_604941 = header.getOrDefault("X-Amz-Date")
  valid_604941 = validateParameter(valid_604941, JString, required = false,
                                 default = nil)
  if valid_604941 != nil:
    section.add "X-Amz-Date", valid_604941
  var valid_604942 = header.getOrDefault("X-Amz-Credential")
  valid_604942 = validateParameter(valid_604942, JString, required = false,
                                 default = nil)
  if valid_604942 != nil:
    section.add "X-Amz-Credential", valid_604942
  var valid_604943 = header.getOrDefault("X-Amz-Security-Token")
  valid_604943 = validateParameter(valid_604943, JString, required = false,
                                 default = nil)
  if valid_604943 != nil:
    section.add "X-Amz-Security-Token", valid_604943
  var valid_604944 = header.getOrDefault("X-Amz-Algorithm")
  valid_604944 = validateParameter(valid_604944, JString, required = false,
                                 default = nil)
  if valid_604944 != nil:
    section.add "X-Amz-Algorithm", valid_604944
  var valid_604945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604945 = validateParameter(valid_604945, JString, required = false,
                                 default = nil)
  if valid_604945 != nil:
    section.add "X-Amz-SignedHeaders", valid_604945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604946: Call_GetVoiceConnectorStreamingConfiguration_604935;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_604946.validator(path, query, header, formData, body)
  let scheme = call_604946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604946.url(scheme.get, call_604946.host, call_604946.base,
                         call_604946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604946, url, valid)

proc call*(call_604947: Call_GetVoiceConnectorStreamingConfiguration_604935;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorStreamingConfiguration
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_604948 = newJObject()
  add(path_604948, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_604947.call(path_604948, nil, nil, nil, nil)

var getVoiceConnectorStreamingConfiguration* = Call_GetVoiceConnectorStreamingConfiguration_604935(
    name: "getVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_GetVoiceConnectorStreamingConfiguration_604936, base: "/",
    url: url_GetVoiceConnectorStreamingConfiguration_604937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorStreamingConfiguration_604965 = ref object of OpenApiRestCall_603389
proc url_DeleteVoiceConnectorStreamingConfiguration_604967(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorStreamingConfiguration_604966(path: JsonNode;
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
  var valid_604968 = path.getOrDefault("voiceConnectorId")
  valid_604968 = validateParameter(valid_604968, JString, required = true,
                                 default = nil)
  if valid_604968 != nil:
    section.add "voiceConnectorId", valid_604968
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
  var valid_604969 = header.getOrDefault("X-Amz-Signature")
  valid_604969 = validateParameter(valid_604969, JString, required = false,
                                 default = nil)
  if valid_604969 != nil:
    section.add "X-Amz-Signature", valid_604969
  var valid_604970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604970 = validateParameter(valid_604970, JString, required = false,
                                 default = nil)
  if valid_604970 != nil:
    section.add "X-Amz-Content-Sha256", valid_604970
  var valid_604971 = header.getOrDefault("X-Amz-Date")
  valid_604971 = validateParameter(valid_604971, JString, required = false,
                                 default = nil)
  if valid_604971 != nil:
    section.add "X-Amz-Date", valid_604971
  var valid_604972 = header.getOrDefault("X-Amz-Credential")
  valid_604972 = validateParameter(valid_604972, JString, required = false,
                                 default = nil)
  if valid_604972 != nil:
    section.add "X-Amz-Credential", valid_604972
  var valid_604973 = header.getOrDefault("X-Amz-Security-Token")
  valid_604973 = validateParameter(valid_604973, JString, required = false,
                                 default = nil)
  if valid_604973 != nil:
    section.add "X-Amz-Security-Token", valid_604973
  var valid_604974 = header.getOrDefault("X-Amz-Algorithm")
  valid_604974 = validateParameter(valid_604974, JString, required = false,
                                 default = nil)
  if valid_604974 != nil:
    section.add "X-Amz-Algorithm", valid_604974
  var valid_604975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604975 = validateParameter(valid_604975, JString, required = false,
                                 default = nil)
  if valid_604975 != nil:
    section.add "X-Amz-SignedHeaders", valid_604975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604976: Call_DeleteVoiceConnectorStreamingConfiguration_604965;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_604976.validator(path, query, header, formData, body)
  let scheme = call_604976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604976.url(scheme.get, call_604976.host, call_604976.base,
                         call_604976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604976, url, valid)

proc call*(call_604977: Call_DeleteVoiceConnectorStreamingConfiguration_604965;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorStreamingConfiguration
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_604978 = newJObject()
  add(path_604978, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_604977.call(path_604978, nil, nil, nil, nil)

var deleteVoiceConnectorStreamingConfiguration* = Call_DeleteVoiceConnectorStreamingConfiguration_604965(
    name: "deleteVoiceConnectorStreamingConfiguration",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_DeleteVoiceConnectorStreamingConfiguration_604966,
    base: "/", url: url_DeleteVoiceConnectorStreamingConfiguration_604967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_604993 = ref object of OpenApiRestCall_603389
proc url_PutVoiceConnectorTermination_604995(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorTermination_604994(path: JsonNode; query: JsonNode;
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
  var valid_604996 = path.getOrDefault("voiceConnectorId")
  valid_604996 = validateParameter(valid_604996, JString, required = true,
                                 default = nil)
  if valid_604996 != nil:
    section.add "voiceConnectorId", valid_604996
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
  var valid_604997 = header.getOrDefault("X-Amz-Signature")
  valid_604997 = validateParameter(valid_604997, JString, required = false,
                                 default = nil)
  if valid_604997 != nil:
    section.add "X-Amz-Signature", valid_604997
  var valid_604998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604998 = validateParameter(valid_604998, JString, required = false,
                                 default = nil)
  if valid_604998 != nil:
    section.add "X-Amz-Content-Sha256", valid_604998
  var valid_604999 = header.getOrDefault("X-Amz-Date")
  valid_604999 = validateParameter(valid_604999, JString, required = false,
                                 default = nil)
  if valid_604999 != nil:
    section.add "X-Amz-Date", valid_604999
  var valid_605000 = header.getOrDefault("X-Amz-Credential")
  valid_605000 = validateParameter(valid_605000, JString, required = false,
                                 default = nil)
  if valid_605000 != nil:
    section.add "X-Amz-Credential", valid_605000
  var valid_605001 = header.getOrDefault("X-Amz-Security-Token")
  valid_605001 = validateParameter(valid_605001, JString, required = false,
                                 default = nil)
  if valid_605001 != nil:
    section.add "X-Amz-Security-Token", valid_605001
  var valid_605002 = header.getOrDefault("X-Amz-Algorithm")
  valid_605002 = validateParameter(valid_605002, JString, required = false,
                                 default = nil)
  if valid_605002 != nil:
    section.add "X-Amz-Algorithm", valid_605002
  var valid_605003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605003 = validateParameter(valid_605003, JString, required = false,
                                 default = nil)
  if valid_605003 != nil:
    section.add "X-Amz-SignedHeaders", valid_605003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605005: Call_PutVoiceConnectorTermination_604993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_605005.validator(path, query, header, formData, body)
  let scheme = call_605005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605005.url(scheme.get, call_605005.host, call_605005.base,
                         call_605005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605005, url, valid)

proc call*(call_605006: Call_PutVoiceConnectorTermination_604993;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_605007 = newJObject()
  var body_605008 = newJObject()
  add(path_605007, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_605008 = body
  result = call_605006.call(path_605007, nil, nil, nil, body_605008)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_604993(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_604994, base: "/",
    url: url_PutVoiceConnectorTermination_604995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_604979 = ref object of OpenApiRestCall_603389
proc url_GetVoiceConnectorTermination_604981(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTermination_604980(path: JsonNode; query: JsonNode;
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
  var valid_604982 = path.getOrDefault("voiceConnectorId")
  valid_604982 = validateParameter(valid_604982, JString, required = true,
                                 default = nil)
  if valid_604982 != nil:
    section.add "voiceConnectorId", valid_604982
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
  var valid_604983 = header.getOrDefault("X-Amz-Signature")
  valid_604983 = validateParameter(valid_604983, JString, required = false,
                                 default = nil)
  if valid_604983 != nil:
    section.add "X-Amz-Signature", valid_604983
  var valid_604984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604984 = validateParameter(valid_604984, JString, required = false,
                                 default = nil)
  if valid_604984 != nil:
    section.add "X-Amz-Content-Sha256", valid_604984
  var valid_604985 = header.getOrDefault("X-Amz-Date")
  valid_604985 = validateParameter(valid_604985, JString, required = false,
                                 default = nil)
  if valid_604985 != nil:
    section.add "X-Amz-Date", valid_604985
  var valid_604986 = header.getOrDefault("X-Amz-Credential")
  valid_604986 = validateParameter(valid_604986, JString, required = false,
                                 default = nil)
  if valid_604986 != nil:
    section.add "X-Amz-Credential", valid_604986
  var valid_604987 = header.getOrDefault("X-Amz-Security-Token")
  valid_604987 = validateParameter(valid_604987, JString, required = false,
                                 default = nil)
  if valid_604987 != nil:
    section.add "X-Amz-Security-Token", valid_604987
  var valid_604988 = header.getOrDefault("X-Amz-Algorithm")
  valid_604988 = validateParameter(valid_604988, JString, required = false,
                                 default = nil)
  if valid_604988 != nil:
    section.add "X-Amz-Algorithm", valid_604988
  var valid_604989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604989 = validateParameter(valid_604989, JString, required = false,
                                 default = nil)
  if valid_604989 != nil:
    section.add "X-Amz-SignedHeaders", valid_604989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604990: Call_GetVoiceConnectorTermination_604979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_604990.validator(path, query, header, formData, body)
  let scheme = call_604990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604990.url(scheme.get, call_604990.host, call_604990.base,
                         call_604990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604990, url, valid)

proc call*(call_604991: Call_GetVoiceConnectorTermination_604979;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_604992 = newJObject()
  add(path_604992, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_604991.call(path_604992, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_604979(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_604980, base: "/",
    url: url_GetVoiceConnectorTermination_604981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_605009 = ref object of OpenApiRestCall_603389
proc url_DeleteVoiceConnectorTermination_605011(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorTermination_605010(path: JsonNode;
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
  var valid_605012 = path.getOrDefault("voiceConnectorId")
  valid_605012 = validateParameter(valid_605012, JString, required = true,
                                 default = nil)
  if valid_605012 != nil:
    section.add "voiceConnectorId", valid_605012
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
  var valid_605013 = header.getOrDefault("X-Amz-Signature")
  valid_605013 = validateParameter(valid_605013, JString, required = false,
                                 default = nil)
  if valid_605013 != nil:
    section.add "X-Amz-Signature", valid_605013
  var valid_605014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605014 = validateParameter(valid_605014, JString, required = false,
                                 default = nil)
  if valid_605014 != nil:
    section.add "X-Amz-Content-Sha256", valid_605014
  var valid_605015 = header.getOrDefault("X-Amz-Date")
  valid_605015 = validateParameter(valid_605015, JString, required = false,
                                 default = nil)
  if valid_605015 != nil:
    section.add "X-Amz-Date", valid_605015
  var valid_605016 = header.getOrDefault("X-Amz-Credential")
  valid_605016 = validateParameter(valid_605016, JString, required = false,
                                 default = nil)
  if valid_605016 != nil:
    section.add "X-Amz-Credential", valid_605016
  var valid_605017 = header.getOrDefault("X-Amz-Security-Token")
  valid_605017 = validateParameter(valid_605017, JString, required = false,
                                 default = nil)
  if valid_605017 != nil:
    section.add "X-Amz-Security-Token", valid_605017
  var valid_605018 = header.getOrDefault("X-Amz-Algorithm")
  valid_605018 = validateParameter(valid_605018, JString, required = false,
                                 default = nil)
  if valid_605018 != nil:
    section.add "X-Amz-Algorithm", valid_605018
  var valid_605019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605019 = validateParameter(valid_605019, JString, required = false,
                                 default = nil)
  if valid_605019 != nil:
    section.add "X-Amz-SignedHeaders", valid_605019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605020: Call_DeleteVoiceConnectorTermination_605009;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_605020.validator(path, query, header, formData, body)
  let scheme = call_605020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605020.url(scheme.get, call_605020.host, call_605020.base,
                         call_605020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605020, url, valid)

proc call*(call_605021: Call_DeleteVoiceConnectorTermination_605009;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_605022 = newJObject()
  add(path_605022, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_605021.call(path_605022, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_605009(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_605010, base: "/",
    url: url_DeleteVoiceConnectorTermination_605011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_605023 = ref object of OpenApiRestCall_603389
proc url_DeleteVoiceConnectorTerminationCredentials_605025(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorTerminationCredentials_605024(path: JsonNode;
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
  var valid_605026 = path.getOrDefault("voiceConnectorId")
  valid_605026 = validateParameter(valid_605026, JString, required = true,
                                 default = nil)
  if valid_605026 != nil:
    section.add "voiceConnectorId", valid_605026
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605027 = query.getOrDefault("operation")
  valid_605027 = validateParameter(valid_605027, JString, required = true,
                                 default = newJString("delete"))
  if valid_605027 != nil:
    section.add "operation", valid_605027
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605028 = header.getOrDefault("X-Amz-Signature")
  valid_605028 = validateParameter(valid_605028, JString, required = false,
                                 default = nil)
  if valid_605028 != nil:
    section.add "X-Amz-Signature", valid_605028
  var valid_605029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605029 = validateParameter(valid_605029, JString, required = false,
                                 default = nil)
  if valid_605029 != nil:
    section.add "X-Amz-Content-Sha256", valid_605029
  var valid_605030 = header.getOrDefault("X-Amz-Date")
  valid_605030 = validateParameter(valid_605030, JString, required = false,
                                 default = nil)
  if valid_605030 != nil:
    section.add "X-Amz-Date", valid_605030
  var valid_605031 = header.getOrDefault("X-Amz-Credential")
  valid_605031 = validateParameter(valid_605031, JString, required = false,
                                 default = nil)
  if valid_605031 != nil:
    section.add "X-Amz-Credential", valid_605031
  var valid_605032 = header.getOrDefault("X-Amz-Security-Token")
  valid_605032 = validateParameter(valid_605032, JString, required = false,
                                 default = nil)
  if valid_605032 != nil:
    section.add "X-Amz-Security-Token", valid_605032
  var valid_605033 = header.getOrDefault("X-Amz-Algorithm")
  valid_605033 = validateParameter(valid_605033, JString, required = false,
                                 default = nil)
  if valid_605033 != nil:
    section.add "X-Amz-Algorithm", valid_605033
  var valid_605034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605034 = validateParameter(valid_605034, JString, required = false,
                                 default = nil)
  if valid_605034 != nil:
    section.add "X-Amz-SignedHeaders", valid_605034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605036: Call_DeleteVoiceConnectorTerminationCredentials_605023;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_605036.validator(path, query, header, formData, body)
  let scheme = call_605036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605036.url(scheme.get, call_605036.host, call_605036.base,
                         call_605036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605036, url, valid)

proc call*(call_605037: Call_DeleteVoiceConnectorTerminationCredentials_605023;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_605038 = newJObject()
  var query_605039 = newJObject()
  var body_605040 = newJObject()
  add(query_605039, "operation", newJString(operation))
  add(path_605038, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_605040 = body
  result = call_605037.call(path_605038, query_605039, nil, nil, body_605040)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_605023(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_605024,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_605025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_605041 = ref object of OpenApiRestCall_603389
proc url_DisassociatePhoneNumberFromUser_605043(protocol: Scheme; host: string;
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

proc validate_DisassociatePhoneNumberFromUser_605042(path: JsonNode;
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
  var valid_605044 = path.getOrDefault("userId")
  valid_605044 = validateParameter(valid_605044, JString, required = true,
                                 default = nil)
  if valid_605044 != nil:
    section.add "userId", valid_605044
  var valid_605045 = path.getOrDefault("accountId")
  valid_605045 = validateParameter(valid_605045, JString, required = true,
                                 default = nil)
  if valid_605045 != nil:
    section.add "accountId", valid_605045
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605046 = query.getOrDefault("operation")
  valid_605046 = validateParameter(valid_605046, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_605046 != nil:
    section.add "operation", valid_605046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605047 = header.getOrDefault("X-Amz-Signature")
  valid_605047 = validateParameter(valid_605047, JString, required = false,
                                 default = nil)
  if valid_605047 != nil:
    section.add "X-Amz-Signature", valid_605047
  var valid_605048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605048 = validateParameter(valid_605048, JString, required = false,
                                 default = nil)
  if valid_605048 != nil:
    section.add "X-Amz-Content-Sha256", valid_605048
  var valid_605049 = header.getOrDefault("X-Amz-Date")
  valid_605049 = validateParameter(valid_605049, JString, required = false,
                                 default = nil)
  if valid_605049 != nil:
    section.add "X-Amz-Date", valid_605049
  var valid_605050 = header.getOrDefault("X-Amz-Credential")
  valid_605050 = validateParameter(valid_605050, JString, required = false,
                                 default = nil)
  if valid_605050 != nil:
    section.add "X-Amz-Credential", valid_605050
  var valid_605051 = header.getOrDefault("X-Amz-Security-Token")
  valid_605051 = validateParameter(valid_605051, JString, required = false,
                                 default = nil)
  if valid_605051 != nil:
    section.add "X-Amz-Security-Token", valid_605051
  var valid_605052 = header.getOrDefault("X-Amz-Algorithm")
  valid_605052 = validateParameter(valid_605052, JString, required = false,
                                 default = nil)
  if valid_605052 != nil:
    section.add "X-Amz-Algorithm", valid_605052
  var valid_605053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605053 = validateParameter(valid_605053, JString, required = false,
                                 default = nil)
  if valid_605053 != nil:
    section.add "X-Amz-SignedHeaders", valid_605053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605054: Call_DisassociatePhoneNumberFromUser_605041;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_605054.validator(path, query, header, formData, body)
  let scheme = call_605054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605054.url(scheme.get, call_605054.host, call_605054.base,
                         call_605054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605054, url, valid)

proc call*(call_605055: Call_DisassociatePhoneNumberFromUser_605041;
          userId: string; accountId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605056 = newJObject()
  var query_605057 = newJObject()
  add(query_605057, "operation", newJString(operation))
  add(path_605056, "userId", newJString(userId))
  add(path_605056, "accountId", newJString(accountId))
  result = call_605055.call(path_605056, query_605057, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_605041(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_605042, base: "/",
    url: url_DisassociatePhoneNumberFromUser_605043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_605058 = ref object of OpenApiRestCall_603389
proc url_DisassociatePhoneNumbersFromVoiceConnector_605060(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnector_605059(path: JsonNode;
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
  var valid_605061 = path.getOrDefault("voiceConnectorId")
  valid_605061 = validateParameter(valid_605061, JString, required = true,
                                 default = nil)
  if valid_605061 != nil:
    section.add "voiceConnectorId", valid_605061
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605062 = query.getOrDefault("operation")
  valid_605062 = validateParameter(valid_605062, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_605062 != nil:
    section.add "operation", valid_605062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605063 = header.getOrDefault("X-Amz-Signature")
  valid_605063 = validateParameter(valid_605063, JString, required = false,
                                 default = nil)
  if valid_605063 != nil:
    section.add "X-Amz-Signature", valid_605063
  var valid_605064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605064 = validateParameter(valid_605064, JString, required = false,
                                 default = nil)
  if valid_605064 != nil:
    section.add "X-Amz-Content-Sha256", valid_605064
  var valid_605065 = header.getOrDefault("X-Amz-Date")
  valid_605065 = validateParameter(valid_605065, JString, required = false,
                                 default = nil)
  if valid_605065 != nil:
    section.add "X-Amz-Date", valid_605065
  var valid_605066 = header.getOrDefault("X-Amz-Credential")
  valid_605066 = validateParameter(valid_605066, JString, required = false,
                                 default = nil)
  if valid_605066 != nil:
    section.add "X-Amz-Credential", valid_605066
  var valid_605067 = header.getOrDefault("X-Amz-Security-Token")
  valid_605067 = validateParameter(valid_605067, JString, required = false,
                                 default = nil)
  if valid_605067 != nil:
    section.add "X-Amz-Security-Token", valid_605067
  var valid_605068 = header.getOrDefault("X-Amz-Algorithm")
  valid_605068 = validateParameter(valid_605068, JString, required = false,
                                 default = nil)
  if valid_605068 != nil:
    section.add "X-Amz-Algorithm", valid_605068
  var valid_605069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605069 = validateParameter(valid_605069, JString, required = false,
                                 default = nil)
  if valid_605069 != nil:
    section.add "X-Amz-SignedHeaders", valid_605069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605071: Call_DisassociatePhoneNumbersFromVoiceConnector_605058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_605071.validator(path, query, header, formData, body)
  let scheme = call_605071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605071.url(scheme.get, call_605071.host, call_605071.base,
                         call_605071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605071, url, valid)

proc call*(call_605072: Call_DisassociatePhoneNumbersFromVoiceConnector_605058;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_605073 = newJObject()
  var query_605074 = newJObject()
  var body_605075 = newJObject()
  add(query_605074, "operation", newJString(operation))
  add(path_605073, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_605075 = body
  result = call_605072.call(path_605073, query_605074, nil, nil, body_605075)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_605058(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_605059,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_605060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_605076 = ref object of OpenApiRestCall_603389
proc url_DisassociatePhoneNumbersFromVoiceConnectorGroup_605078(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_605077(
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
  var valid_605079 = path.getOrDefault("voiceConnectorGroupId")
  valid_605079 = validateParameter(valid_605079, JString, required = true,
                                 default = nil)
  if valid_605079 != nil:
    section.add "voiceConnectorGroupId", valid_605079
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605080 = query.getOrDefault("operation")
  valid_605080 = validateParameter(valid_605080, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_605080 != nil:
    section.add "operation", valid_605080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605081 = header.getOrDefault("X-Amz-Signature")
  valid_605081 = validateParameter(valid_605081, JString, required = false,
                                 default = nil)
  if valid_605081 != nil:
    section.add "X-Amz-Signature", valid_605081
  var valid_605082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605082 = validateParameter(valid_605082, JString, required = false,
                                 default = nil)
  if valid_605082 != nil:
    section.add "X-Amz-Content-Sha256", valid_605082
  var valid_605083 = header.getOrDefault("X-Amz-Date")
  valid_605083 = validateParameter(valid_605083, JString, required = false,
                                 default = nil)
  if valid_605083 != nil:
    section.add "X-Amz-Date", valid_605083
  var valid_605084 = header.getOrDefault("X-Amz-Credential")
  valid_605084 = validateParameter(valid_605084, JString, required = false,
                                 default = nil)
  if valid_605084 != nil:
    section.add "X-Amz-Credential", valid_605084
  var valid_605085 = header.getOrDefault("X-Amz-Security-Token")
  valid_605085 = validateParameter(valid_605085, JString, required = false,
                                 default = nil)
  if valid_605085 != nil:
    section.add "X-Amz-Security-Token", valid_605085
  var valid_605086 = header.getOrDefault("X-Amz-Algorithm")
  valid_605086 = validateParameter(valid_605086, JString, required = false,
                                 default = nil)
  if valid_605086 != nil:
    section.add "X-Amz-Algorithm", valid_605086
  var valid_605087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605087 = validateParameter(valid_605087, JString, required = false,
                                 default = nil)
  if valid_605087 != nil:
    section.add "X-Amz-SignedHeaders", valid_605087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605089: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_605076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_605089.validator(path, query, header, formData, body)
  let scheme = call_605089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605089.url(scheme.get, call_605089.host, call_605089.base,
                         call_605089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605089, url, valid)

proc call*(call_605090: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_605076;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnectorGroup
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_605091 = newJObject()
  var query_605092 = newJObject()
  var body_605093 = newJObject()
  add(path_605091, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_605092, "operation", newJString(operation))
  if body != nil:
    body_605093 = body
  result = call_605090.call(path_605091, query_605092, nil, nil, body_605093)

var disassociatePhoneNumbersFromVoiceConnectorGroup* = Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_605076(
    name: "disassociatePhoneNumbersFromVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_605077,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnectorGroup_605078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSigninDelegateGroupsFromAccount_605094 = ref object of OpenApiRestCall_603389
proc url_DisassociateSigninDelegateGroupsFromAccount_605096(protocol: Scheme;
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

proc validate_DisassociateSigninDelegateGroupsFromAccount_605095(path: JsonNode;
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
  var valid_605097 = path.getOrDefault("accountId")
  valid_605097 = validateParameter(valid_605097, JString, required = true,
                                 default = nil)
  if valid_605097 != nil:
    section.add "accountId", valid_605097
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605098 = query.getOrDefault("operation")
  valid_605098 = validateParameter(valid_605098, JString, required = true, default = newJString(
      "disassociate-signin-delegate-groups"))
  if valid_605098 != nil:
    section.add "operation", valid_605098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605099 = header.getOrDefault("X-Amz-Signature")
  valid_605099 = validateParameter(valid_605099, JString, required = false,
                                 default = nil)
  if valid_605099 != nil:
    section.add "X-Amz-Signature", valid_605099
  var valid_605100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "X-Amz-Content-Sha256", valid_605100
  var valid_605101 = header.getOrDefault("X-Amz-Date")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "X-Amz-Date", valid_605101
  var valid_605102 = header.getOrDefault("X-Amz-Credential")
  valid_605102 = validateParameter(valid_605102, JString, required = false,
                                 default = nil)
  if valid_605102 != nil:
    section.add "X-Amz-Credential", valid_605102
  var valid_605103 = header.getOrDefault("X-Amz-Security-Token")
  valid_605103 = validateParameter(valid_605103, JString, required = false,
                                 default = nil)
  if valid_605103 != nil:
    section.add "X-Amz-Security-Token", valid_605103
  var valid_605104 = header.getOrDefault("X-Amz-Algorithm")
  valid_605104 = validateParameter(valid_605104, JString, required = false,
                                 default = nil)
  if valid_605104 != nil:
    section.add "X-Amz-Algorithm", valid_605104
  var valid_605105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605105 = validateParameter(valid_605105, JString, required = false,
                                 default = nil)
  if valid_605105 != nil:
    section.add "X-Amz-SignedHeaders", valid_605105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605107: Call_DisassociateSigninDelegateGroupsFromAccount_605094;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ## 
  let valid = call_605107.validator(path, query, header, formData, body)
  let scheme = call_605107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605107.url(scheme.get, call_605107.host, call_605107.base,
                         call_605107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605107, url, valid)

proc call*(call_605108: Call_DisassociateSigninDelegateGroupsFromAccount_605094;
          body: JsonNode; accountId: string;
          operation: string = "disassociate-signin-delegate-groups"): Recallable =
  ## disassociateSigninDelegateGroupsFromAccount
  ## Disassociates the specified sign-in delegate groups from the specified Amazon Chime account.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605109 = newJObject()
  var query_605110 = newJObject()
  var body_605111 = newJObject()
  add(query_605110, "operation", newJString(operation))
  if body != nil:
    body_605111 = body
  add(path_605109, "accountId", newJString(accountId))
  result = call_605108.call(path_605109, query_605110, nil, nil, body_605111)

var disassociateSigninDelegateGroupsFromAccount* = Call_DisassociateSigninDelegateGroupsFromAccount_605094(
    name: "disassociateSigninDelegateGroupsFromAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts/{accountId}#operation=disassociate-signin-delegate-groups",
    validator: validate_DisassociateSigninDelegateGroupsFromAccount_605095,
    base: "/", url: url_DisassociateSigninDelegateGroupsFromAccount_605096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_605126 = ref object of OpenApiRestCall_603389
proc url_UpdateAccountSettings_605128(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccountSettings_605127(path: JsonNode; query: JsonNode;
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
  var valid_605129 = path.getOrDefault("accountId")
  valid_605129 = validateParameter(valid_605129, JString, required = true,
                                 default = nil)
  if valid_605129 != nil:
    section.add "accountId", valid_605129
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
  var valid_605130 = header.getOrDefault("X-Amz-Signature")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "X-Amz-Signature", valid_605130
  var valid_605131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "X-Amz-Content-Sha256", valid_605131
  var valid_605132 = header.getOrDefault("X-Amz-Date")
  valid_605132 = validateParameter(valid_605132, JString, required = false,
                                 default = nil)
  if valid_605132 != nil:
    section.add "X-Amz-Date", valid_605132
  var valid_605133 = header.getOrDefault("X-Amz-Credential")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "X-Amz-Credential", valid_605133
  var valid_605134 = header.getOrDefault("X-Amz-Security-Token")
  valid_605134 = validateParameter(valid_605134, JString, required = false,
                                 default = nil)
  if valid_605134 != nil:
    section.add "X-Amz-Security-Token", valid_605134
  var valid_605135 = header.getOrDefault("X-Amz-Algorithm")
  valid_605135 = validateParameter(valid_605135, JString, required = false,
                                 default = nil)
  if valid_605135 != nil:
    section.add "X-Amz-Algorithm", valid_605135
  var valid_605136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605136 = validateParameter(valid_605136, JString, required = false,
                                 default = nil)
  if valid_605136 != nil:
    section.add "X-Amz-SignedHeaders", valid_605136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605138: Call_UpdateAccountSettings_605126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_605138.validator(path, query, header, formData, body)
  let scheme = call_605138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605138.url(scheme.get, call_605138.host, call_605138.base,
                         call_605138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605138, url, valid)

proc call*(call_605139: Call_UpdateAccountSettings_605126; body: JsonNode;
          accountId: string): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605140 = newJObject()
  var body_605141 = newJObject()
  if body != nil:
    body_605141 = body
  add(path_605140, "accountId", newJString(accountId))
  result = call_605139.call(path_605140, nil, nil, nil, body_605141)

var updateAccountSettings* = Call_UpdateAccountSettings_605126(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_605127, base: "/",
    url: url_UpdateAccountSettings_605128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_605112 = ref object of OpenApiRestCall_603389
proc url_GetAccountSettings_605114(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_605113(path: JsonNode; query: JsonNode;
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
  var valid_605115 = path.getOrDefault("accountId")
  valid_605115 = validateParameter(valid_605115, JString, required = true,
                                 default = nil)
  if valid_605115 != nil:
    section.add "accountId", valid_605115
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
  var valid_605116 = header.getOrDefault("X-Amz-Signature")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-Signature", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-Content-Sha256", valid_605117
  var valid_605118 = header.getOrDefault("X-Amz-Date")
  valid_605118 = validateParameter(valid_605118, JString, required = false,
                                 default = nil)
  if valid_605118 != nil:
    section.add "X-Amz-Date", valid_605118
  var valid_605119 = header.getOrDefault("X-Amz-Credential")
  valid_605119 = validateParameter(valid_605119, JString, required = false,
                                 default = nil)
  if valid_605119 != nil:
    section.add "X-Amz-Credential", valid_605119
  var valid_605120 = header.getOrDefault("X-Amz-Security-Token")
  valid_605120 = validateParameter(valid_605120, JString, required = false,
                                 default = nil)
  if valid_605120 != nil:
    section.add "X-Amz-Security-Token", valid_605120
  var valid_605121 = header.getOrDefault("X-Amz-Algorithm")
  valid_605121 = validateParameter(valid_605121, JString, required = false,
                                 default = nil)
  if valid_605121 != nil:
    section.add "X-Amz-Algorithm", valid_605121
  var valid_605122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605122 = validateParameter(valid_605122, JString, required = false,
                                 default = nil)
  if valid_605122 != nil:
    section.add "X-Amz-SignedHeaders", valid_605122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605123: Call_GetAccountSettings_605112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_605123.validator(path, query, header, formData, body)
  let scheme = call_605123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605123.url(scheme.get, call_605123.host, call_605123.base,
                         call_605123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605123, url, valid)

proc call*(call_605124: Call_GetAccountSettings_605112; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605125 = newJObject()
  add(path_605125, "accountId", newJString(accountId))
  result = call_605124.call(path_605125, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_605112(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_605113, base: "/",
    url: url_GetAccountSettings_605114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_605157 = ref object of OpenApiRestCall_603389
proc url_UpdateBot_605159(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateBot_605158(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605160 = path.getOrDefault("botId")
  valid_605160 = validateParameter(valid_605160, JString, required = true,
                                 default = nil)
  if valid_605160 != nil:
    section.add "botId", valid_605160
  var valid_605161 = path.getOrDefault("accountId")
  valid_605161 = validateParameter(valid_605161, JString, required = true,
                                 default = nil)
  if valid_605161 != nil:
    section.add "accountId", valid_605161
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
  var valid_605162 = header.getOrDefault("X-Amz-Signature")
  valid_605162 = validateParameter(valid_605162, JString, required = false,
                                 default = nil)
  if valid_605162 != nil:
    section.add "X-Amz-Signature", valid_605162
  var valid_605163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605163 = validateParameter(valid_605163, JString, required = false,
                                 default = nil)
  if valid_605163 != nil:
    section.add "X-Amz-Content-Sha256", valid_605163
  var valid_605164 = header.getOrDefault("X-Amz-Date")
  valid_605164 = validateParameter(valid_605164, JString, required = false,
                                 default = nil)
  if valid_605164 != nil:
    section.add "X-Amz-Date", valid_605164
  var valid_605165 = header.getOrDefault("X-Amz-Credential")
  valid_605165 = validateParameter(valid_605165, JString, required = false,
                                 default = nil)
  if valid_605165 != nil:
    section.add "X-Amz-Credential", valid_605165
  var valid_605166 = header.getOrDefault("X-Amz-Security-Token")
  valid_605166 = validateParameter(valid_605166, JString, required = false,
                                 default = nil)
  if valid_605166 != nil:
    section.add "X-Amz-Security-Token", valid_605166
  var valid_605167 = header.getOrDefault("X-Amz-Algorithm")
  valid_605167 = validateParameter(valid_605167, JString, required = false,
                                 default = nil)
  if valid_605167 != nil:
    section.add "X-Amz-Algorithm", valid_605167
  var valid_605168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605168 = validateParameter(valid_605168, JString, required = false,
                                 default = nil)
  if valid_605168 != nil:
    section.add "X-Amz-SignedHeaders", valid_605168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605170: Call_UpdateBot_605157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_605170.validator(path, query, header, formData, body)
  let scheme = call_605170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605170.url(scheme.get, call_605170.host, call_605170.base,
                         call_605170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605170, url, valid)

proc call*(call_605171: Call_UpdateBot_605157; botId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605172 = newJObject()
  var body_605173 = newJObject()
  add(path_605172, "botId", newJString(botId))
  if body != nil:
    body_605173 = body
  add(path_605172, "accountId", newJString(accountId))
  result = call_605171.call(path_605172, nil, nil, nil, body_605173)

var updateBot* = Call_UpdateBot_605157(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_605158,
                                    base: "/", url: url_UpdateBot_605159,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_605142 = ref object of OpenApiRestCall_603389
proc url_GetBot_605144(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_605143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605145 = path.getOrDefault("botId")
  valid_605145 = validateParameter(valid_605145, JString, required = true,
                                 default = nil)
  if valid_605145 != nil:
    section.add "botId", valid_605145
  var valid_605146 = path.getOrDefault("accountId")
  valid_605146 = validateParameter(valid_605146, JString, required = true,
                                 default = nil)
  if valid_605146 != nil:
    section.add "accountId", valid_605146
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
  var valid_605147 = header.getOrDefault("X-Amz-Signature")
  valid_605147 = validateParameter(valid_605147, JString, required = false,
                                 default = nil)
  if valid_605147 != nil:
    section.add "X-Amz-Signature", valid_605147
  var valid_605148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605148 = validateParameter(valid_605148, JString, required = false,
                                 default = nil)
  if valid_605148 != nil:
    section.add "X-Amz-Content-Sha256", valid_605148
  var valid_605149 = header.getOrDefault("X-Amz-Date")
  valid_605149 = validateParameter(valid_605149, JString, required = false,
                                 default = nil)
  if valid_605149 != nil:
    section.add "X-Amz-Date", valid_605149
  var valid_605150 = header.getOrDefault("X-Amz-Credential")
  valid_605150 = validateParameter(valid_605150, JString, required = false,
                                 default = nil)
  if valid_605150 != nil:
    section.add "X-Amz-Credential", valid_605150
  var valid_605151 = header.getOrDefault("X-Amz-Security-Token")
  valid_605151 = validateParameter(valid_605151, JString, required = false,
                                 default = nil)
  if valid_605151 != nil:
    section.add "X-Amz-Security-Token", valid_605151
  var valid_605152 = header.getOrDefault("X-Amz-Algorithm")
  valid_605152 = validateParameter(valid_605152, JString, required = false,
                                 default = nil)
  if valid_605152 != nil:
    section.add "X-Amz-Algorithm", valid_605152
  var valid_605153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605153 = validateParameter(valid_605153, JString, required = false,
                                 default = nil)
  if valid_605153 != nil:
    section.add "X-Amz-SignedHeaders", valid_605153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605154: Call_GetBot_605142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_605154.validator(path, query, header, formData, body)
  let scheme = call_605154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605154.url(scheme.get, call_605154.host, call_605154.base,
                         call_605154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605154, url, valid)

proc call*(call_605155: Call_GetBot_605142; botId: string; accountId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605156 = newJObject()
  add(path_605156, "botId", newJString(botId))
  add(path_605156, "accountId", newJString(accountId))
  result = call_605155.call(path_605156, nil, nil, nil, nil)

var getBot* = Call_GetBot_605142(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_605143, base: "/",
                              url: url_GetBot_605144,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_605186 = ref object of OpenApiRestCall_603389
proc url_UpdateGlobalSettings_605188(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGlobalSettings_605187(path: JsonNode; query: JsonNode;
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
  var valid_605189 = header.getOrDefault("X-Amz-Signature")
  valid_605189 = validateParameter(valid_605189, JString, required = false,
                                 default = nil)
  if valid_605189 != nil:
    section.add "X-Amz-Signature", valid_605189
  var valid_605190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605190 = validateParameter(valid_605190, JString, required = false,
                                 default = nil)
  if valid_605190 != nil:
    section.add "X-Amz-Content-Sha256", valid_605190
  var valid_605191 = header.getOrDefault("X-Amz-Date")
  valid_605191 = validateParameter(valid_605191, JString, required = false,
                                 default = nil)
  if valid_605191 != nil:
    section.add "X-Amz-Date", valid_605191
  var valid_605192 = header.getOrDefault("X-Amz-Credential")
  valid_605192 = validateParameter(valid_605192, JString, required = false,
                                 default = nil)
  if valid_605192 != nil:
    section.add "X-Amz-Credential", valid_605192
  var valid_605193 = header.getOrDefault("X-Amz-Security-Token")
  valid_605193 = validateParameter(valid_605193, JString, required = false,
                                 default = nil)
  if valid_605193 != nil:
    section.add "X-Amz-Security-Token", valid_605193
  var valid_605194 = header.getOrDefault("X-Amz-Algorithm")
  valid_605194 = validateParameter(valid_605194, JString, required = false,
                                 default = nil)
  if valid_605194 != nil:
    section.add "X-Amz-Algorithm", valid_605194
  var valid_605195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605195 = validateParameter(valid_605195, JString, required = false,
                                 default = nil)
  if valid_605195 != nil:
    section.add "X-Amz-SignedHeaders", valid_605195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605197: Call_UpdateGlobalSettings_605186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_605197.validator(path, query, header, formData, body)
  let scheme = call_605197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605197.url(scheme.get, call_605197.host, call_605197.base,
                         call_605197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605197, url, valid)

proc call*(call_605198: Call_UpdateGlobalSettings_605186; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_605199 = newJObject()
  if body != nil:
    body_605199 = body
  result = call_605198.call(nil, nil, nil, nil, body_605199)

var updateGlobalSettings* = Call_UpdateGlobalSettings_605186(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_605187, base: "/",
    url: url_UpdateGlobalSettings_605188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_605174 = ref object of OpenApiRestCall_603389
proc url_GetGlobalSettings_605176(protocol: Scheme; host: string; base: string;
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

proc validate_GetGlobalSettings_605175(path: JsonNode; query: JsonNode;
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
  var valid_605177 = header.getOrDefault("X-Amz-Signature")
  valid_605177 = validateParameter(valid_605177, JString, required = false,
                                 default = nil)
  if valid_605177 != nil:
    section.add "X-Amz-Signature", valid_605177
  var valid_605178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605178 = validateParameter(valid_605178, JString, required = false,
                                 default = nil)
  if valid_605178 != nil:
    section.add "X-Amz-Content-Sha256", valid_605178
  var valid_605179 = header.getOrDefault("X-Amz-Date")
  valid_605179 = validateParameter(valid_605179, JString, required = false,
                                 default = nil)
  if valid_605179 != nil:
    section.add "X-Amz-Date", valid_605179
  var valid_605180 = header.getOrDefault("X-Amz-Credential")
  valid_605180 = validateParameter(valid_605180, JString, required = false,
                                 default = nil)
  if valid_605180 != nil:
    section.add "X-Amz-Credential", valid_605180
  var valid_605181 = header.getOrDefault("X-Amz-Security-Token")
  valid_605181 = validateParameter(valid_605181, JString, required = false,
                                 default = nil)
  if valid_605181 != nil:
    section.add "X-Amz-Security-Token", valid_605181
  var valid_605182 = header.getOrDefault("X-Amz-Algorithm")
  valid_605182 = validateParameter(valid_605182, JString, required = false,
                                 default = nil)
  if valid_605182 != nil:
    section.add "X-Amz-Algorithm", valid_605182
  var valid_605183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605183 = validateParameter(valid_605183, JString, required = false,
                                 default = nil)
  if valid_605183 != nil:
    section.add "X-Amz-SignedHeaders", valid_605183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605184: Call_GetGlobalSettings_605174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_605184.validator(path, query, header, formData, body)
  let scheme = call_605184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605184.url(scheme.get, call_605184.host, call_605184.base,
                         call_605184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605184, url, valid)

proc call*(call_605185: Call_GetGlobalSettings_605174): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_605185.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_605174(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_605175, base: "/",
    url: url_GetGlobalSettings_605176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_605200 = ref object of OpenApiRestCall_603389
proc url_GetPhoneNumberOrder_605202(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberOrder_605201(path: JsonNode; query: JsonNode;
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
  var valid_605203 = path.getOrDefault("phoneNumberOrderId")
  valid_605203 = validateParameter(valid_605203, JString, required = true,
                                 default = nil)
  if valid_605203 != nil:
    section.add "phoneNumberOrderId", valid_605203
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
  var valid_605204 = header.getOrDefault("X-Amz-Signature")
  valid_605204 = validateParameter(valid_605204, JString, required = false,
                                 default = nil)
  if valid_605204 != nil:
    section.add "X-Amz-Signature", valid_605204
  var valid_605205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605205 = validateParameter(valid_605205, JString, required = false,
                                 default = nil)
  if valid_605205 != nil:
    section.add "X-Amz-Content-Sha256", valid_605205
  var valid_605206 = header.getOrDefault("X-Amz-Date")
  valid_605206 = validateParameter(valid_605206, JString, required = false,
                                 default = nil)
  if valid_605206 != nil:
    section.add "X-Amz-Date", valid_605206
  var valid_605207 = header.getOrDefault("X-Amz-Credential")
  valid_605207 = validateParameter(valid_605207, JString, required = false,
                                 default = nil)
  if valid_605207 != nil:
    section.add "X-Amz-Credential", valid_605207
  var valid_605208 = header.getOrDefault("X-Amz-Security-Token")
  valid_605208 = validateParameter(valid_605208, JString, required = false,
                                 default = nil)
  if valid_605208 != nil:
    section.add "X-Amz-Security-Token", valid_605208
  var valid_605209 = header.getOrDefault("X-Amz-Algorithm")
  valid_605209 = validateParameter(valid_605209, JString, required = false,
                                 default = nil)
  if valid_605209 != nil:
    section.add "X-Amz-Algorithm", valid_605209
  var valid_605210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605210 = validateParameter(valid_605210, JString, required = false,
                                 default = nil)
  if valid_605210 != nil:
    section.add "X-Amz-SignedHeaders", valid_605210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605211: Call_GetPhoneNumberOrder_605200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_605211.validator(path, query, header, formData, body)
  let scheme = call_605211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605211.url(scheme.get, call_605211.host, call_605211.base,
                         call_605211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605211, url, valid)

proc call*(call_605212: Call_GetPhoneNumberOrder_605200; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_605213 = newJObject()
  add(path_605213, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_605212.call(path_605213, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_605200(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_605201, base: "/",
    url: url_GetPhoneNumberOrder_605202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumberSettings_605226 = ref object of OpenApiRestCall_603389
proc url_UpdatePhoneNumberSettings_605228(protocol: Scheme; host: string;
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

proc validate_UpdatePhoneNumberSettings_605227(path: JsonNode; query: JsonNode;
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
  var valid_605229 = header.getOrDefault("X-Amz-Signature")
  valid_605229 = validateParameter(valid_605229, JString, required = false,
                                 default = nil)
  if valid_605229 != nil:
    section.add "X-Amz-Signature", valid_605229
  var valid_605230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605230 = validateParameter(valid_605230, JString, required = false,
                                 default = nil)
  if valid_605230 != nil:
    section.add "X-Amz-Content-Sha256", valid_605230
  var valid_605231 = header.getOrDefault("X-Amz-Date")
  valid_605231 = validateParameter(valid_605231, JString, required = false,
                                 default = nil)
  if valid_605231 != nil:
    section.add "X-Amz-Date", valid_605231
  var valid_605232 = header.getOrDefault("X-Amz-Credential")
  valid_605232 = validateParameter(valid_605232, JString, required = false,
                                 default = nil)
  if valid_605232 != nil:
    section.add "X-Amz-Credential", valid_605232
  var valid_605233 = header.getOrDefault("X-Amz-Security-Token")
  valid_605233 = validateParameter(valid_605233, JString, required = false,
                                 default = nil)
  if valid_605233 != nil:
    section.add "X-Amz-Security-Token", valid_605233
  var valid_605234 = header.getOrDefault("X-Amz-Algorithm")
  valid_605234 = validateParameter(valid_605234, JString, required = false,
                                 default = nil)
  if valid_605234 != nil:
    section.add "X-Amz-Algorithm", valid_605234
  var valid_605235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605235 = validateParameter(valid_605235, JString, required = false,
                                 default = nil)
  if valid_605235 != nil:
    section.add "X-Amz-SignedHeaders", valid_605235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605237: Call_UpdatePhoneNumberSettings_605226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ## 
  let valid = call_605237.validator(path, query, header, formData, body)
  let scheme = call_605237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605237.url(scheme.get, call_605237.host, call_605237.base,
                         call_605237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605237, url, valid)

proc call*(call_605238: Call_UpdatePhoneNumberSettings_605226; body: JsonNode): Recallable =
  ## updatePhoneNumberSettings
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ##   body: JObject (required)
  var body_605239 = newJObject()
  if body != nil:
    body_605239 = body
  result = call_605238.call(nil, nil, nil, nil, body_605239)

var updatePhoneNumberSettings* = Call_UpdatePhoneNumberSettings_605226(
    name: "updatePhoneNumberSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_UpdatePhoneNumberSettings_605227, base: "/",
    url: url_UpdatePhoneNumberSettings_605228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberSettings_605214 = ref object of OpenApiRestCall_603389
proc url_GetPhoneNumberSettings_605216(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberSettings_605215(path: JsonNode; query: JsonNode;
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
  var valid_605217 = header.getOrDefault("X-Amz-Signature")
  valid_605217 = validateParameter(valid_605217, JString, required = false,
                                 default = nil)
  if valid_605217 != nil:
    section.add "X-Amz-Signature", valid_605217
  var valid_605218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605218 = validateParameter(valid_605218, JString, required = false,
                                 default = nil)
  if valid_605218 != nil:
    section.add "X-Amz-Content-Sha256", valid_605218
  var valid_605219 = header.getOrDefault("X-Amz-Date")
  valid_605219 = validateParameter(valid_605219, JString, required = false,
                                 default = nil)
  if valid_605219 != nil:
    section.add "X-Amz-Date", valid_605219
  var valid_605220 = header.getOrDefault("X-Amz-Credential")
  valid_605220 = validateParameter(valid_605220, JString, required = false,
                                 default = nil)
  if valid_605220 != nil:
    section.add "X-Amz-Credential", valid_605220
  var valid_605221 = header.getOrDefault("X-Amz-Security-Token")
  valid_605221 = validateParameter(valid_605221, JString, required = false,
                                 default = nil)
  if valid_605221 != nil:
    section.add "X-Amz-Security-Token", valid_605221
  var valid_605222 = header.getOrDefault("X-Amz-Algorithm")
  valid_605222 = validateParameter(valid_605222, JString, required = false,
                                 default = nil)
  if valid_605222 != nil:
    section.add "X-Amz-Algorithm", valid_605222
  var valid_605223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605223 = validateParameter(valid_605223, JString, required = false,
                                 default = nil)
  if valid_605223 != nil:
    section.add "X-Amz-SignedHeaders", valid_605223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605224: Call_GetPhoneNumberSettings_605214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  let valid = call_605224.validator(path, query, header, formData, body)
  let scheme = call_605224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605224.url(scheme.get, call_605224.host, call_605224.base,
                         call_605224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605224, url, valid)

proc call*(call_605225: Call_GetPhoneNumberSettings_605214): Recallable =
  ## getPhoneNumberSettings
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  result = call_605225.call(nil, nil, nil, nil, nil)

var getPhoneNumberSettings* = Call_GetPhoneNumberSettings_605214(
    name: "getPhoneNumberSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_GetPhoneNumberSettings_605215, base: "/",
    url: url_GetPhoneNumberSettings_605216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_605255 = ref object of OpenApiRestCall_603389
proc url_UpdateUser_605257(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_605256(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605258 = path.getOrDefault("userId")
  valid_605258 = validateParameter(valid_605258, JString, required = true,
                                 default = nil)
  if valid_605258 != nil:
    section.add "userId", valid_605258
  var valid_605259 = path.getOrDefault("accountId")
  valid_605259 = validateParameter(valid_605259, JString, required = true,
                                 default = nil)
  if valid_605259 != nil:
    section.add "accountId", valid_605259
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
  var valid_605260 = header.getOrDefault("X-Amz-Signature")
  valid_605260 = validateParameter(valid_605260, JString, required = false,
                                 default = nil)
  if valid_605260 != nil:
    section.add "X-Amz-Signature", valid_605260
  var valid_605261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605261 = validateParameter(valid_605261, JString, required = false,
                                 default = nil)
  if valid_605261 != nil:
    section.add "X-Amz-Content-Sha256", valid_605261
  var valid_605262 = header.getOrDefault("X-Amz-Date")
  valid_605262 = validateParameter(valid_605262, JString, required = false,
                                 default = nil)
  if valid_605262 != nil:
    section.add "X-Amz-Date", valid_605262
  var valid_605263 = header.getOrDefault("X-Amz-Credential")
  valid_605263 = validateParameter(valid_605263, JString, required = false,
                                 default = nil)
  if valid_605263 != nil:
    section.add "X-Amz-Credential", valid_605263
  var valid_605264 = header.getOrDefault("X-Amz-Security-Token")
  valid_605264 = validateParameter(valid_605264, JString, required = false,
                                 default = nil)
  if valid_605264 != nil:
    section.add "X-Amz-Security-Token", valid_605264
  var valid_605265 = header.getOrDefault("X-Amz-Algorithm")
  valid_605265 = validateParameter(valid_605265, JString, required = false,
                                 default = nil)
  if valid_605265 != nil:
    section.add "X-Amz-Algorithm", valid_605265
  var valid_605266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605266 = validateParameter(valid_605266, JString, required = false,
                                 default = nil)
  if valid_605266 != nil:
    section.add "X-Amz-SignedHeaders", valid_605266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605268: Call_UpdateUser_605255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_605268.validator(path, query, header, formData, body)
  let scheme = call_605268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605268.url(scheme.get, call_605268.host, call_605268.base,
                         call_605268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605268, url, valid)

proc call*(call_605269: Call_UpdateUser_605255; userId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605270 = newJObject()
  var body_605271 = newJObject()
  add(path_605270, "userId", newJString(userId))
  if body != nil:
    body_605271 = body
  add(path_605270, "accountId", newJString(accountId))
  result = call_605269.call(path_605270, nil, nil, nil, body_605271)

var updateUser* = Call_UpdateUser_605255(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_605256,
                                      base: "/", url: url_UpdateUser_605257,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_605240 = ref object of OpenApiRestCall_603389
proc url_GetUser_605242(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_605241(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605243 = path.getOrDefault("userId")
  valid_605243 = validateParameter(valid_605243, JString, required = true,
                                 default = nil)
  if valid_605243 != nil:
    section.add "userId", valid_605243
  var valid_605244 = path.getOrDefault("accountId")
  valid_605244 = validateParameter(valid_605244, JString, required = true,
                                 default = nil)
  if valid_605244 != nil:
    section.add "accountId", valid_605244
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
  var valid_605245 = header.getOrDefault("X-Amz-Signature")
  valid_605245 = validateParameter(valid_605245, JString, required = false,
                                 default = nil)
  if valid_605245 != nil:
    section.add "X-Amz-Signature", valid_605245
  var valid_605246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605246 = validateParameter(valid_605246, JString, required = false,
                                 default = nil)
  if valid_605246 != nil:
    section.add "X-Amz-Content-Sha256", valid_605246
  var valid_605247 = header.getOrDefault("X-Amz-Date")
  valid_605247 = validateParameter(valid_605247, JString, required = false,
                                 default = nil)
  if valid_605247 != nil:
    section.add "X-Amz-Date", valid_605247
  var valid_605248 = header.getOrDefault("X-Amz-Credential")
  valid_605248 = validateParameter(valid_605248, JString, required = false,
                                 default = nil)
  if valid_605248 != nil:
    section.add "X-Amz-Credential", valid_605248
  var valid_605249 = header.getOrDefault("X-Amz-Security-Token")
  valid_605249 = validateParameter(valid_605249, JString, required = false,
                                 default = nil)
  if valid_605249 != nil:
    section.add "X-Amz-Security-Token", valid_605249
  var valid_605250 = header.getOrDefault("X-Amz-Algorithm")
  valid_605250 = validateParameter(valid_605250, JString, required = false,
                                 default = nil)
  if valid_605250 != nil:
    section.add "X-Amz-Algorithm", valid_605250
  var valid_605251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605251 = validateParameter(valid_605251, JString, required = false,
                                 default = nil)
  if valid_605251 != nil:
    section.add "X-Amz-SignedHeaders", valid_605251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605252: Call_GetUser_605240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_605252.validator(path, query, header, formData, body)
  let scheme = call_605252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605252.url(scheme.get, call_605252.host, call_605252.base,
                         call_605252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605252, url, valid)

proc call*(call_605253: Call_GetUser_605240; userId: string; accountId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605254 = newJObject()
  add(path_605254, "userId", newJString(userId))
  add(path_605254, "accountId", newJString(accountId))
  result = call_605253.call(path_605254, nil, nil, nil, nil)

var getUser* = Call_GetUser_605240(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_605241, base: "/",
                                url: url_GetUser_605242,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_605287 = ref object of OpenApiRestCall_603389
proc url_UpdateUserSettings_605289(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserSettings_605288(path: JsonNode; query: JsonNode;
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
  var valid_605290 = path.getOrDefault("userId")
  valid_605290 = validateParameter(valid_605290, JString, required = true,
                                 default = nil)
  if valid_605290 != nil:
    section.add "userId", valid_605290
  var valid_605291 = path.getOrDefault("accountId")
  valid_605291 = validateParameter(valid_605291, JString, required = true,
                                 default = nil)
  if valid_605291 != nil:
    section.add "accountId", valid_605291
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
  var valid_605292 = header.getOrDefault("X-Amz-Signature")
  valid_605292 = validateParameter(valid_605292, JString, required = false,
                                 default = nil)
  if valid_605292 != nil:
    section.add "X-Amz-Signature", valid_605292
  var valid_605293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605293 = validateParameter(valid_605293, JString, required = false,
                                 default = nil)
  if valid_605293 != nil:
    section.add "X-Amz-Content-Sha256", valid_605293
  var valid_605294 = header.getOrDefault("X-Amz-Date")
  valid_605294 = validateParameter(valid_605294, JString, required = false,
                                 default = nil)
  if valid_605294 != nil:
    section.add "X-Amz-Date", valid_605294
  var valid_605295 = header.getOrDefault("X-Amz-Credential")
  valid_605295 = validateParameter(valid_605295, JString, required = false,
                                 default = nil)
  if valid_605295 != nil:
    section.add "X-Amz-Credential", valid_605295
  var valid_605296 = header.getOrDefault("X-Amz-Security-Token")
  valid_605296 = validateParameter(valid_605296, JString, required = false,
                                 default = nil)
  if valid_605296 != nil:
    section.add "X-Amz-Security-Token", valid_605296
  var valid_605297 = header.getOrDefault("X-Amz-Algorithm")
  valid_605297 = validateParameter(valid_605297, JString, required = false,
                                 default = nil)
  if valid_605297 != nil:
    section.add "X-Amz-Algorithm", valid_605297
  var valid_605298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605298 = validateParameter(valid_605298, JString, required = false,
                                 default = nil)
  if valid_605298 != nil:
    section.add "X-Amz-SignedHeaders", valid_605298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605300: Call_UpdateUserSettings_605287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_605300.validator(path, query, header, formData, body)
  let scheme = call_605300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605300.url(scheme.get, call_605300.host, call_605300.base,
                         call_605300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605300, url, valid)

proc call*(call_605301: Call_UpdateUserSettings_605287; userId: string;
          body: JsonNode; accountId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605302 = newJObject()
  var body_605303 = newJObject()
  add(path_605302, "userId", newJString(userId))
  if body != nil:
    body_605303 = body
  add(path_605302, "accountId", newJString(accountId))
  result = call_605301.call(path_605302, nil, nil, nil, body_605303)

var updateUserSettings* = Call_UpdateUserSettings_605287(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_605288, base: "/",
    url: url_UpdateUserSettings_605289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_605272 = ref object of OpenApiRestCall_603389
proc url_GetUserSettings_605274(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserSettings_605273(path: JsonNode; query: JsonNode;
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
  var valid_605275 = path.getOrDefault("userId")
  valid_605275 = validateParameter(valid_605275, JString, required = true,
                                 default = nil)
  if valid_605275 != nil:
    section.add "userId", valid_605275
  var valid_605276 = path.getOrDefault("accountId")
  valid_605276 = validateParameter(valid_605276, JString, required = true,
                                 default = nil)
  if valid_605276 != nil:
    section.add "accountId", valid_605276
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
  var valid_605277 = header.getOrDefault("X-Amz-Signature")
  valid_605277 = validateParameter(valid_605277, JString, required = false,
                                 default = nil)
  if valid_605277 != nil:
    section.add "X-Amz-Signature", valid_605277
  var valid_605278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605278 = validateParameter(valid_605278, JString, required = false,
                                 default = nil)
  if valid_605278 != nil:
    section.add "X-Amz-Content-Sha256", valid_605278
  var valid_605279 = header.getOrDefault("X-Amz-Date")
  valid_605279 = validateParameter(valid_605279, JString, required = false,
                                 default = nil)
  if valid_605279 != nil:
    section.add "X-Amz-Date", valid_605279
  var valid_605280 = header.getOrDefault("X-Amz-Credential")
  valid_605280 = validateParameter(valid_605280, JString, required = false,
                                 default = nil)
  if valid_605280 != nil:
    section.add "X-Amz-Credential", valid_605280
  var valid_605281 = header.getOrDefault("X-Amz-Security-Token")
  valid_605281 = validateParameter(valid_605281, JString, required = false,
                                 default = nil)
  if valid_605281 != nil:
    section.add "X-Amz-Security-Token", valid_605281
  var valid_605282 = header.getOrDefault("X-Amz-Algorithm")
  valid_605282 = validateParameter(valid_605282, JString, required = false,
                                 default = nil)
  if valid_605282 != nil:
    section.add "X-Amz-Algorithm", valid_605282
  var valid_605283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605283 = validateParameter(valid_605283, JString, required = false,
                                 default = nil)
  if valid_605283 != nil:
    section.add "X-Amz-SignedHeaders", valid_605283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605284: Call_GetUserSettings_605272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_605284.validator(path, query, header, formData, body)
  let scheme = call_605284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605284.url(scheme.get, call_605284.host, call_605284.base,
                         call_605284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605284, url, valid)

proc call*(call_605285: Call_GetUserSettings_605272; userId: string;
          accountId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605286 = newJObject()
  add(path_605286, "userId", newJString(userId))
  add(path_605286, "accountId", newJString(accountId))
  result = call_605285.call(path_605286, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_605272(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_605273, base: "/", url: url_GetUserSettings_605274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorLoggingConfiguration_605318 = ref object of OpenApiRestCall_603389
proc url_PutVoiceConnectorLoggingConfiguration_605320(protocol: Scheme;
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

proc validate_PutVoiceConnectorLoggingConfiguration_605319(path: JsonNode;
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
  var valid_605321 = path.getOrDefault("voiceConnectorId")
  valid_605321 = validateParameter(valid_605321, JString, required = true,
                                 default = nil)
  if valid_605321 != nil:
    section.add "voiceConnectorId", valid_605321
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
  var valid_605322 = header.getOrDefault("X-Amz-Signature")
  valid_605322 = validateParameter(valid_605322, JString, required = false,
                                 default = nil)
  if valid_605322 != nil:
    section.add "X-Amz-Signature", valid_605322
  var valid_605323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605323 = validateParameter(valid_605323, JString, required = false,
                                 default = nil)
  if valid_605323 != nil:
    section.add "X-Amz-Content-Sha256", valid_605323
  var valid_605324 = header.getOrDefault("X-Amz-Date")
  valid_605324 = validateParameter(valid_605324, JString, required = false,
                                 default = nil)
  if valid_605324 != nil:
    section.add "X-Amz-Date", valid_605324
  var valid_605325 = header.getOrDefault("X-Amz-Credential")
  valid_605325 = validateParameter(valid_605325, JString, required = false,
                                 default = nil)
  if valid_605325 != nil:
    section.add "X-Amz-Credential", valid_605325
  var valid_605326 = header.getOrDefault("X-Amz-Security-Token")
  valid_605326 = validateParameter(valid_605326, JString, required = false,
                                 default = nil)
  if valid_605326 != nil:
    section.add "X-Amz-Security-Token", valid_605326
  var valid_605327 = header.getOrDefault("X-Amz-Algorithm")
  valid_605327 = validateParameter(valid_605327, JString, required = false,
                                 default = nil)
  if valid_605327 != nil:
    section.add "X-Amz-Algorithm", valid_605327
  var valid_605328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605328 = validateParameter(valid_605328, JString, required = false,
                                 default = nil)
  if valid_605328 != nil:
    section.add "X-Amz-SignedHeaders", valid_605328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605330: Call_PutVoiceConnectorLoggingConfiguration_605318;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_605330.validator(path, query, header, formData, body)
  let scheme = call_605330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605330.url(scheme.get, call_605330.host, call_605330.base,
                         call_605330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605330, url, valid)

proc call*(call_605331: Call_PutVoiceConnectorLoggingConfiguration_605318;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorLoggingConfiguration
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_605332 = newJObject()
  var body_605333 = newJObject()
  add(path_605332, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_605333 = body
  result = call_605331.call(path_605332, nil, nil, nil, body_605333)

var putVoiceConnectorLoggingConfiguration* = Call_PutVoiceConnectorLoggingConfiguration_605318(
    name: "putVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_PutVoiceConnectorLoggingConfiguration_605319, base: "/",
    url: url_PutVoiceConnectorLoggingConfiguration_605320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorLoggingConfiguration_605304 = ref object of OpenApiRestCall_603389
proc url_GetVoiceConnectorLoggingConfiguration_605306(protocol: Scheme;
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

proc validate_GetVoiceConnectorLoggingConfiguration_605305(path: JsonNode;
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
  var valid_605307 = path.getOrDefault("voiceConnectorId")
  valid_605307 = validateParameter(valid_605307, JString, required = true,
                                 default = nil)
  if valid_605307 != nil:
    section.add "voiceConnectorId", valid_605307
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
  var valid_605308 = header.getOrDefault("X-Amz-Signature")
  valid_605308 = validateParameter(valid_605308, JString, required = false,
                                 default = nil)
  if valid_605308 != nil:
    section.add "X-Amz-Signature", valid_605308
  var valid_605309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605309 = validateParameter(valid_605309, JString, required = false,
                                 default = nil)
  if valid_605309 != nil:
    section.add "X-Amz-Content-Sha256", valid_605309
  var valid_605310 = header.getOrDefault("X-Amz-Date")
  valid_605310 = validateParameter(valid_605310, JString, required = false,
                                 default = nil)
  if valid_605310 != nil:
    section.add "X-Amz-Date", valid_605310
  var valid_605311 = header.getOrDefault("X-Amz-Credential")
  valid_605311 = validateParameter(valid_605311, JString, required = false,
                                 default = nil)
  if valid_605311 != nil:
    section.add "X-Amz-Credential", valid_605311
  var valid_605312 = header.getOrDefault("X-Amz-Security-Token")
  valid_605312 = validateParameter(valid_605312, JString, required = false,
                                 default = nil)
  if valid_605312 != nil:
    section.add "X-Amz-Security-Token", valid_605312
  var valid_605313 = header.getOrDefault("X-Amz-Algorithm")
  valid_605313 = validateParameter(valid_605313, JString, required = false,
                                 default = nil)
  if valid_605313 != nil:
    section.add "X-Amz-Algorithm", valid_605313
  var valid_605314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605314 = validateParameter(valid_605314, JString, required = false,
                                 default = nil)
  if valid_605314 != nil:
    section.add "X-Amz-SignedHeaders", valid_605314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605315: Call_GetVoiceConnectorLoggingConfiguration_605304;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_605315.validator(path, query, header, formData, body)
  let scheme = call_605315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605315.url(scheme.get, call_605315.host, call_605315.base,
                         call_605315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605315, url, valid)

proc call*(call_605316: Call_GetVoiceConnectorLoggingConfiguration_605304;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorLoggingConfiguration
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_605317 = newJObject()
  add(path_605317, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_605316.call(path_605317, nil, nil, nil, nil)

var getVoiceConnectorLoggingConfiguration* = Call_GetVoiceConnectorLoggingConfiguration_605304(
    name: "getVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_GetVoiceConnectorLoggingConfiguration_605305, base: "/",
    url: url_GetVoiceConnectorLoggingConfiguration_605306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_605334 = ref object of OpenApiRestCall_603389
proc url_GetVoiceConnectorTerminationHealth_605336(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTerminationHealth_605335(path: JsonNode;
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
  var valid_605337 = path.getOrDefault("voiceConnectorId")
  valid_605337 = validateParameter(valid_605337, JString, required = true,
                                 default = nil)
  if valid_605337 != nil:
    section.add "voiceConnectorId", valid_605337
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
  var valid_605338 = header.getOrDefault("X-Amz-Signature")
  valid_605338 = validateParameter(valid_605338, JString, required = false,
                                 default = nil)
  if valid_605338 != nil:
    section.add "X-Amz-Signature", valid_605338
  var valid_605339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605339 = validateParameter(valid_605339, JString, required = false,
                                 default = nil)
  if valid_605339 != nil:
    section.add "X-Amz-Content-Sha256", valid_605339
  var valid_605340 = header.getOrDefault("X-Amz-Date")
  valid_605340 = validateParameter(valid_605340, JString, required = false,
                                 default = nil)
  if valid_605340 != nil:
    section.add "X-Amz-Date", valid_605340
  var valid_605341 = header.getOrDefault("X-Amz-Credential")
  valid_605341 = validateParameter(valid_605341, JString, required = false,
                                 default = nil)
  if valid_605341 != nil:
    section.add "X-Amz-Credential", valid_605341
  var valid_605342 = header.getOrDefault("X-Amz-Security-Token")
  valid_605342 = validateParameter(valid_605342, JString, required = false,
                                 default = nil)
  if valid_605342 != nil:
    section.add "X-Amz-Security-Token", valid_605342
  var valid_605343 = header.getOrDefault("X-Amz-Algorithm")
  valid_605343 = validateParameter(valid_605343, JString, required = false,
                                 default = nil)
  if valid_605343 != nil:
    section.add "X-Amz-Algorithm", valid_605343
  var valid_605344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605344 = validateParameter(valid_605344, JString, required = false,
                                 default = nil)
  if valid_605344 != nil:
    section.add "X-Amz-SignedHeaders", valid_605344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605345: Call_GetVoiceConnectorTerminationHealth_605334;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_605345.validator(path, query, header, formData, body)
  let scheme = call_605345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605345.url(scheme.get, call_605345.host, call_605345.base,
                         call_605345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605345, url, valid)

proc call*(call_605346: Call_GetVoiceConnectorTerminationHealth_605334;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_605347 = newJObject()
  add(path_605347, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_605346.call(path_605347, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_605334(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_605335, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_605336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_605348 = ref object of OpenApiRestCall_603389
proc url_InviteUsers_605350(protocol: Scheme; host: string; base: string;
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

proc validate_InviteUsers_605349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605351 = path.getOrDefault("accountId")
  valid_605351 = validateParameter(valid_605351, JString, required = true,
                                 default = nil)
  if valid_605351 != nil:
    section.add "accountId", valid_605351
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605352 = query.getOrDefault("operation")
  valid_605352 = validateParameter(valid_605352, JString, required = true,
                                 default = newJString("add"))
  if valid_605352 != nil:
    section.add "operation", valid_605352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605353 = header.getOrDefault("X-Amz-Signature")
  valid_605353 = validateParameter(valid_605353, JString, required = false,
                                 default = nil)
  if valid_605353 != nil:
    section.add "X-Amz-Signature", valid_605353
  var valid_605354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605354 = validateParameter(valid_605354, JString, required = false,
                                 default = nil)
  if valid_605354 != nil:
    section.add "X-Amz-Content-Sha256", valid_605354
  var valid_605355 = header.getOrDefault("X-Amz-Date")
  valid_605355 = validateParameter(valid_605355, JString, required = false,
                                 default = nil)
  if valid_605355 != nil:
    section.add "X-Amz-Date", valid_605355
  var valid_605356 = header.getOrDefault("X-Amz-Credential")
  valid_605356 = validateParameter(valid_605356, JString, required = false,
                                 default = nil)
  if valid_605356 != nil:
    section.add "X-Amz-Credential", valid_605356
  var valid_605357 = header.getOrDefault("X-Amz-Security-Token")
  valid_605357 = validateParameter(valid_605357, JString, required = false,
                                 default = nil)
  if valid_605357 != nil:
    section.add "X-Amz-Security-Token", valid_605357
  var valid_605358 = header.getOrDefault("X-Amz-Algorithm")
  valid_605358 = validateParameter(valid_605358, JString, required = false,
                                 default = nil)
  if valid_605358 != nil:
    section.add "X-Amz-Algorithm", valid_605358
  var valid_605359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605359 = validateParameter(valid_605359, JString, required = false,
                                 default = nil)
  if valid_605359 != nil:
    section.add "X-Amz-SignedHeaders", valid_605359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605361: Call_InviteUsers_605348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_605361.validator(path, query, header, formData, body)
  let scheme = call_605361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605361.url(scheme.get, call_605361.host, call_605361.base,
                         call_605361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605361, url, valid)

proc call*(call_605362: Call_InviteUsers_605348; body: JsonNode; accountId: string;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605363 = newJObject()
  var query_605364 = newJObject()
  var body_605365 = newJObject()
  add(query_605364, "operation", newJString(operation))
  if body != nil:
    body_605365 = body
  add(path_605363, "accountId", newJString(accountId))
  result = call_605362.call(path_605363, query_605364, nil, nil, body_605365)

var inviteUsers* = Call_InviteUsers_605348(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_605349,
                                        base: "/", url: url_InviteUsers_605350,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_605366 = ref object of OpenApiRestCall_603389
proc url_ListPhoneNumbers_605368(protocol: Scheme; host: string; base: string;
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

proc validate_ListPhoneNumbers_605367(path: JsonNode; query: JsonNode;
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
  var valid_605369 = query.getOrDefault("MaxResults")
  valid_605369 = validateParameter(valid_605369, JString, required = false,
                                 default = nil)
  if valid_605369 != nil:
    section.add "MaxResults", valid_605369
  var valid_605370 = query.getOrDefault("NextToken")
  valid_605370 = validateParameter(valid_605370, JString, required = false,
                                 default = nil)
  if valid_605370 != nil:
    section.add "NextToken", valid_605370
  var valid_605371 = query.getOrDefault("product-type")
  valid_605371 = validateParameter(valid_605371, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_605371 != nil:
    section.add "product-type", valid_605371
  var valid_605372 = query.getOrDefault("filter-name")
  valid_605372 = validateParameter(valid_605372, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_605372 != nil:
    section.add "filter-name", valid_605372
  var valid_605373 = query.getOrDefault("max-results")
  valid_605373 = validateParameter(valid_605373, JInt, required = false, default = nil)
  if valid_605373 != nil:
    section.add "max-results", valid_605373
  var valid_605374 = query.getOrDefault("status")
  valid_605374 = validateParameter(valid_605374, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_605374 != nil:
    section.add "status", valid_605374
  var valid_605375 = query.getOrDefault("filter-value")
  valid_605375 = validateParameter(valid_605375, JString, required = false,
                                 default = nil)
  if valid_605375 != nil:
    section.add "filter-value", valid_605375
  var valid_605376 = query.getOrDefault("next-token")
  valid_605376 = validateParameter(valid_605376, JString, required = false,
                                 default = nil)
  if valid_605376 != nil:
    section.add "next-token", valid_605376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605377 = header.getOrDefault("X-Amz-Signature")
  valid_605377 = validateParameter(valid_605377, JString, required = false,
                                 default = nil)
  if valid_605377 != nil:
    section.add "X-Amz-Signature", valid_605377
  var valid_605378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605378 = validateParameter(valid_605378, JString, required = false,
                                 default = nil)
  if valid_605378 != nil:
    section.add "X-Amz-Content-Sha256", valid_605378
  var valid_605379 = header.getOrDefault("X-Amz-Date")
  valid_605379 = validateParameter(valid_605379, JString, required = false,
                                 default = nil)
  if valid_605379 != nil:
    section.add "X-Amz-Date", valid_605379
  var valid_605380 = header.getOrDefault("X-Amz-Credential")
  valid_605380 = validateParameter(valid_605380, JString, required = false,
                                 default = nil)
  if valid_605380 != nil:
    section.add "X-Amz-Credential", valid_605380
  var valid_605381 = header.getOrDefault("X-Amz-Security-Token")
  valid_605381 = validateParameter(valid_605381, JString, required = false,
                                 default = nil)
  if valid_605381 != nil:
    section.add "X-Amz-Security-Token", valid_605381
  var valid_605382 = header.getOrDefault("X-Amz-Algorithm")
  valid_605382 = validateParameter(valid_605382, JString, required = false,
                                 default = nil)
  if valid_605382 != nil:
    section.add "X-Amz-Algorithm", valid_605382
  var valid_605383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605383 = validateParameter(valid_605383, JString, required = false,
                                 default = nil)
  if valid_605383 != nil:
    section.add "X-Amz-SignedHeaders", valid_605383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605384: Call_ListPhoneNumbers_605366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  let valid = call_605384.validator(path, query, header, formData, body)
  let scheme = call_605384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605384.url(scheme.get, call_605384.host, call_605384.base,
                         call_605384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605384, url, valid)

proc call*(call_605385: Call_ListPhoneNumbers_605366; MaxResults: string = "";
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
  var query_605386 = newJObject()
  add(query_605386, "MaxResults", newJString(MaxResults))
  add(query_605386, "NextToken", newJString(NextToken))
  add(query_605386, "product-type", newJString(productType))
  add(query_605386, "filter-name", newJString(filterName))
  add(query_605386, "max-results", newJInt(maxResults))
  add(query_605386, "status", newJString(status))
  add(query_605386, "filter-value", newJString(filterValue))
  add(query_605386, "next-token", newJString(nextToken))
  result = call_605385.call(nil, query_605386, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_605366(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_605367, base: "/",
    url: url_ListPhoneNumbers_605368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_605387 = ref object of OpenApiRestCall_603389
proc url_ListVoiceConnectorTerminationCredentials_605389(protocol: Scheme;
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

proc validate_ListVoiceConnectorTerminationCredentials_605388(path: JsonNode;
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
  var valid_605390 = path.getOrDefault("voiceConnectorId")
  valid_605390 = validateParameter(valid_605390, JString, required = true,
                                 default = nil)
  if valid_605390 != nil:
    section.add "voiceConnectorId", valid_605390
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
  var valid_605391 = header.getOrDefault("X-Amz-Signature")
  valid_605391 = validateParameter(valid_605391, JString, required = false,
                                 default = nil)
  if valid_605391 != nil:
    section.add "X-Amz-Signature", valid_605391
  var valid_605392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605392 = validateParameter(valid_605392, JString, required = false,
                                 default = nil)
  if valid_605392 != nil:
    section.add "X-Amz-Content-Sha256", valid_605392
  var valid_605393 = header.getOrDefault("X-Amz-Date")
  valid_605393 = validateParameter(valid_605393, JString, required = false,
                                 default = nil)
  if valid_605393 != nil:
    section.add "X-Amz-Date", valid_605393
  var valid_605394 = header.getOrDefault("X-Amz-Credential")
  valid_605394 = validateParameter(valid_605394, JString, required = false,
                                 default = nil)
  if valid_605394 != nil:
    section.add "X-Amz-Credential", valid_605394
  var valid_605395 = header.getOrDefault("X-Amz-Security-Token")
  valid_605395 = validateParameter(valid_605395, JString, required = false,
                                 default = nil)
  if valid_605395 != nil:
    section.add "X-Amz-Security-Token", valid_605395
  var valid_605396 = header.getOrDefault("X-Amz-Algorithm")
  valid_605396 = validateParameter(valid_605396, JString, required = false,
                                 default = nil)
  if valid_605396 != nil:
    section.add "X-Amz-Algorithm", valid_605396
  var valid_605397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605397 = validateParameter(valid_605397, JString, required = false,
                                 default = nil)
  if valid_605397 != nil:
    section.add "X-Amz-SignedHeaders", valid_605397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605398: Call_ListVoiceConnectorTerminationCredentials_605387;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_605398.validator(path, query, header, formData, body)
  let scheme = call_605398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605398.url(scheme.get, call_605398.host, call_605398.base,
                         call_605398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605398, url, valid)

proc call*(call_605399: Call_ListVoiceConnectorTerminationCredentials_605387;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_605400 = newJObject()
  add(path_605400, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_605399.call(path_605400, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_605387(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_605388,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_605389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_605401 = ref object of OpenApiRestCall_603389
proc url_LogoutUser_605403(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_LogoutUser_605402(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605404 = path.getOrDefault("userId")
  valid_605404 = validateParameter(valid_605404, JString, required = true,
                                 default = nil)
  if valid_605404 != nil:
    section.add "userId", valid_605404
  var valid_605405 = path.getOrDefault("accountId")
  valid_605405 = validateParameter(valid_605405, JString, required = true,
                                 default = nil)
  if valid_605405 != nil:
    section.add "accountId", valid_605405
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605406 = query.getOrDefault("operation")
  valid_605406 = validateParameter(valid_605406, JString, required = true,
                                 default = newJString("logout"))
  if valid_605406 != nil:
    section.add "operation", valid_605406
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605407 = header.getOrDefault("X-Amz-Signature")
  valid_605407 = validateParameter(valid_605407, JString, required = false,
                                 default = nil)
  if valid_605407 != nil:
    section.add "X-Amz-Signature", valid_605407
  var valid_605408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605408 = validateParameter(valid_605408, JString, required = false,
                                 default = nil)
  if valid_605408 != nil:
    section.add "X-Amz-Content-Sha256", valid_605408
  var valid_605409 = header.getOrDefault("X-Amz-Date")
  valid_605409 = validateParameter(valid_605409, JString, required = false,
                                 default = nil)
  if valid_605409 != nil:
    section.add "X-Amz-Date", valid_605409
  var valid_605410 = header.getOrDefault("X-Amz-Credential")
  valid_605410 = validateParameter(valid_605410, JString, required = false,
                                 default = nil)
  if valid_605410 != nil:
    section.add "X-Amz-Credential", valid_605410
  var valid_605411 = header.getOrDefault("X-Amz-Security-Token")
  valid_605411 = validateParameter(valid_605411, JString, required = false,
                                 default = nil)
  if valid_605411 != nil:
    section.add "X-Amz-Security-Token", valid_605411
  var valid_605412 = header.getOrDefault("X-Amz-Algorithm")
  valid_605412 = validateParameter(valid_605412, JString, required = false,
                                 default = nil)
  if valid_605412 != nil:
    section.add "X-Amz-Algorithm", valid_605412
  var valid_605413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605413 = validateParameter(valid_605413, JString, required = false,
                                 default = nil)
  if valid_605413 != nil:
    section.add "X-Amz-SignedHeaders", valid_605413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605414: Call_LogoutUser_605401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_605414.validator(path, query, header, formData, body)
  let scheme = call_605414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605414.url(scheme.get, call_605414.host, call_605414.base,
                         call_605414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605414, url, valid)

proc call*(call_605415: Call_LogoutUser_605401; userId: string; accountId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605416 = newJObject()
  var query_605417 = newJObject()
  add(query_605417, "operation", newJString(operation))
  add(path_605416, "userId", newJString(userId))
  add(path_605416, "accountId", newJString(accountId))
  result = call_605415.call(path_605416, query_605417, nil, nil, nil)

var logoutUser* = Call_LogoutUser_605401(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_605402,
                                      base: "/", url: url_LogoutUser_605403,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_605418 = ref object of OpenApiRestCall_603389
proc url_PutVoiceConnectorTerminationCredentials_605420(protocol: Scheme;
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

proc validate_PutVoiceConnectorTerminationCredentials_605419(path: JsonNode;
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
  var valid_605421 = path.getOrDefault("voiceConnectorId")
  valid_605421 = validateParameter(valid_605421, JString, required = true,
                                 default = nil)
  if valid_605421 != nil:
    section.add "voiceConnectorId", valid_605421
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605422 = query.getOrDefault("operation")
  valid_605422 = validateParameter(valid_605422, JString, required = true,
                                 default = newJString("put"))
  if valid_605422 != nil:
    section.add "operation", valid_605422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605423 = header.getOrDefault("X-Amz-Signature")
  valid_605423 = validateParameter(valid_605423, JString, required = false,
                                 default = nil)
  if valid_605423 != nil:
    section.add "X-Amz-Signature", valid_605423
  var valid_605424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605424 = validateParameter(valid_605424, JString, required = false,
                                 default = nil)
  if valid_605424 != nil:
    section.add "X-Amz-Content-Sha256", valid_605424
  var valid_605425 = header.getOrDefault("X-Amz-Date")
  valid_605425 = validateParameter(valid_605425, JString, required = false,
                                 default = nil)
  if valid_605425 != nil:
    section.add "X-Amz-Date", valid_605425
  var valid_605426 = header.getOrDefault("X-Amz-Credential")
  valid_605426 = validateParameter(valid_605426, JString, required = false,
                                 default = nil)
  if valid_605426 != nil:
    section.add "X-Amz-Credential", valid_605426
  var valid_605427 = header.getOrDefault("X-Amz-Security-Token")
  valid_605427 = validateParameter(valid_605427, JString, required = false,
                                 default = nil)
  if valid_605427 != nil:
    section.add "X-Amz-Security-Token", valid_605427
  var valid_605428 = header.getOrDefault("X-Amz-Algorithm")
  valid_605428 = validateParameter(valid_605428, JString, required = false,
                                 default = nil)
  if valid_605428 != nil:
    section.add "X-Amz-Algorithm", valid_605428
  var valid_605429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605429 = validateParameter(valid_605429, JString, required = false,
                                 default = nil)
  if valid_605429 != nil:
    section.add "X-Amz-SignedHeaders", valid_605429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605431: Call_PutVoiceConnectorTerminationCredentials_605418;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_605431.validator(path, query, header, formData, body)
  let scheme = call_605431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605431.url(scheme.get, call_605431.host, call_605431.base,
                         call_605431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605431, url, valid)

proc call*(call_605432: Call_PutVoiceConnectorTerminationCredentials_605418;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_605433 = newJObject()
  var query_605434 = newJObject()
  var body_605435 = newJObject()
  add(query_605434, "operation", newJString(operation))
  add(path_605433, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_605435 = body
  result = call_605432.call(path_605433, query_605434, nil, nil, body_605435)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_605418(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_605419, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_605420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_605436 = ref object of OpenApiRestCall_603389
proc url_RegenerateSecurityToken_605438(protocol: Scheme; host: string; base: string;
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

proc validate_RegenerateSecurityToken_605437(path: JsonNode; query: JsonNode;
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
  var valid_605439 = path.getOrDefault("botId")
  valid_605439 = validateParameter(valid_605439, JString, required = true,
                                 default = nil)
  if valid_605439 != nil:
    section.add "botId", valid_605439
  var valid_605440 = path.getOrDefault("accountId")
  valid_605440 = validateParameter(valid_605440, JString, required = true,
                                 default = nil)
  if valid_605440 != nil:
    section.add "accountId", valid_605440
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605441 = query.getOrDefault("operation")
  valid_605441 = validateParameter(valid_605441, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_605441 != nil:
    section.add "operation", valid_605441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605442 = header.getOrDefault("X-Amz-Signature")
  valid_605442 = validateParameter(valid_605442, JString, required = false,
                                 default = nil)
  if valid_605442 != nil:
    section.add "X-Amz-Signature", valid_605442
  var valid_605443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605443 = validateParameter(valid_605443, JString, required = false,
                                 default = nil)
  if valid_605443 != nil:
    section.add "X-Amz-Content-Sha256", valid_605443
  var valid_605444 = header.getOrDefault("X-Amz-Date")
  valid_605444 = validateParameter(valid_605444, JString, required = false,
                                 default = nil)
  if valid_605444 != nil:
    section.add "X-Amz-Date", valid_605444
  var valid_605445 = header.getOrDefault("X-Amz-Credential")
  valid_605445 = validateParameter(valid_605445, JString, required = false,
                                 default = nil)
  if valid_605445 != nil:
    section.add "X-Amz-Credential", valid_605445
  var valid_605446 = header.getOrDefault("X-Amz-Security-Token")
  valid_605446 = validateParameter(valid_605446, JString, required = false,
                                 default = nil)
  if valid_605446 != nil:
    section.add "X-Amz-Security-Token", valid_605446
  var valid_605447 = header.getOrDefault("X-Amz-Algorithm")
  valid_605447 = validateParameter(valid_605447, JString, required = false,
                                 default = nil)
  if valid_605447 != nil:
    section.add "X-Amz-Algorithm", valid_605447
  var valid_605448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605448 = validateParameter(valid_605448, JString, required = false,
                                 default = nil)
  if valid_605448 != nil:
    section.add "X-Amz-SignedHeaders", valid_605448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605449: Call_RegenerateSecurityToken_605436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_605449.validator(path, query, header, formData, body)
  let scheme = call_605449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605449.url(scheme.get, call_605449.host, call_605449.base,
                         call_605449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605449, url, valid)

proc call*(call_605450: Call_RegenerateSecurityToken_605436; botId: string;
          accountId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605451 = newJObject()
  var query_605452 = newJObject()
  add(path_605451, "botId", newJString(botId))
  add(query_605452, "operation", newJString(operation))
  add(path_605451, "accountId", newJString(accountId))
  result = call_605450.call(path_605451, query_605452, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_605436(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_605437, base: "/",
    url: url_RegenerateSecurityToken_605438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_605453 = ref object of OpenApiRestCall_603389
proc url_ResetPersonalPIN_605455(protocol: Scheme; host: string; base: string;
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

proc validate_ResetPersonalPIN_605454(path: JsonNode; query: JsonNode;
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
  var valid_605456 = path.getOrDefault("userId")
  valid_605456 = validateParameter(valid_605456, JString, required = true,
                                 default = nil)
  if valid_605456 != nil:
    section.add "userId", valid_605456
  var valid_605457 = path.getOrDefault("accountId")
  valid_605457 = validateParameter(valid_605457, JString, required = true,
                                 default = nil)
  if valid_605457 != nil:
    section.add "accountId", valid_605457
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605458 = query.getOrDefault("operation")
  valid_605458 = validateParameter(valid_605458, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_605458 != nil:
    section.add "operation", valid_605458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605459 = header.getOrDefault("X-Amz-Signature")
  valid_605459 = validateParameter(valid_605459, JString, required = false,
                                 default = nil)
  if valid_605459 != nil:
    section.add "X-Amz-Signature", valid_605459
  var valid_605460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605460 = validateParameter(valid_605460, JString, required = false,
                                 default = nil)
  if valid_605460 != nil:
    section.add "X-Amz-Content-Sha256", valid_605460
  var valid_605461 = header.getOrDefault("X-Amz-Date")
  valid_605461 = validateParameter(valid_605461, JString, required = false,
                                 default = nil)
  if valid_605461 != nil:
    section.add "X-Amz-Date", valid_605461
  var valid_605462 = header.getOrDefault("X-Amz-Credential")
  valid_605462 = validateParameter(valid_605462, JString, required = false,
                                 default = nil)
  if valid_605462 != nil:
    section.add "X-Amz-Credential", valid_605462
  var valid_605463 = header.getOrDefault("X-Amz-Security-Token")
  valid_605463 = validateParameter(valid_605463, JString, required = false,
                                 default = nil)
  if valid_605463 != nil:
    section.add "X-Amz-Security-Token", valid_605463
  var valid_605464 = header.getOrDefault("X-Amz-Algorithm")
  valid_605464 = validateParameter(valid_605464, JString, required = false,
                                 default = nil)
  if valid_605464 != nil:
    section.add "X-Amz-Algorithm", valid_605464
  var valid_605465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605465 = validateParameter(valid_605465, JString, required = false,
                                 default = nil)
  if valid_605465 != nil:
    section.add "X-Amz-SignedHeaders", valid_605465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605466: Call_ResetPersonalPIN_605453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_605466.validator(path, query, header, formData, body)
  let scheme = call_605466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605466.url(scheme.get, call_605466.host, call_605466.base,
                         call_605466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605466, url, valid)

proc call*(call_605467: Call_ResetPersonalPIN_605453; userId: string;
          accountId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_605468 = newJObject()
  var query_605469 = newJObject()
  add(query_605469, "operation", newJString(operation))
  add(path_605468, "userId", newJString(userId))
  add(path_605468, "accountId", newJString(accountId))
  result = call_605467.call(path_605468, query_605469, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_605453(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_605454, base: "/",
    url: url_ResetPersonalPIN_605455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_605470 = ref object of OpenApiRestCall_603389
proc url_RestorePhoneNumber_605472(protocol: Scheme; host: string; base: string;
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

proc validate_RestorePhoneNumber_605471(path: JsonNode; query: JsonNode;
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
  var valid_605473 = path.getOrDefault("phoneNumberId")
  valid_605473 = validateParameter(valid_605473, JString, required = true,
                                 default = nil)
  if valid_605473 != nil:
    section.add "phoneNumberId", valid_605473
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_605474 = query.getOrDefault("operation")
  valid_605474 = validateParameter(valid_605474, JString, required = true,
                                 default = newJString("restore"))
  if valid_605474 != nil:
    section.add "operation", valid_605474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605475 = header.getOrDefault("X-Amz-Signature")
  valid_605475 = validateParameter(valid_605475, JString, required = false,
                                 default = nil)
  if valid_605475 != nil:
    section.add "X-Amz-Signature", valid_605475
  var valid_605476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605476 = validateParameter(valid_605476, JString, required = false,
                                 default = nil)
  if valid_605476 != nil:
    section.add "X-Amz-Content-Sha256", valid_605476
  var valid_605477 = header.getOrDefault("X-Amz-Date")
  valid_605477 = validateParameter(valid_605477, JString, required = false,
                                 default = nil)
  if valid_605477 != nil:
    section.add "X-Amz-Date", valid_605477
  var valid_605478 = header.getOrDefault("X-Amz-Credential")
  valid_605478 = validateParameter(valid_605478, JString, required = false,
                                 default = nil)
  if valid_605478 != nil:
    section.add "X-Amz-Credential", valid_605478
  var valid_605479 = header.getOrDefault("X-Amz-Security-Token")
  valid_605479 = validateParameter(valid_605479, JString, required = false,
                                 default = nil)
  if valid_605479 != nil:
    section.add "X-Amz-Security-Token", valid_605479
  var valid_605480 = header.getOrDefault("X-Amz-Algorithm")
  valid_605480 = validateParameter(valid_605480, JString, required = false,
                                 default = nil)
  if valid_605480 != nil:
    section.add "X-Amz-Algorithm", valid_605480
  var valid_605481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605481 = validateParameter(valid_605481, JString, required = false,
                                 default = nil)
  if valid_605481 != nil:
    section.add "X-Amz-SignedHeaders", valid_605481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605482: Call_RestorePhoneNumber_605470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_605482.validator(path, query, header, formData, body)
  let scheme = call_605482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605482.url(scheme.get, call_605482.host, call_605482.base,
                         call_605482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605482, url, valid)

proc call*(call_605483: Call_RestorePhoneNumber_605470; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_605484 = newJObject()
  var query_605485 = newJObject()
  add(path_605484, "phoneNumberId", newJString(phoneNumberId))
  add(query_605485, "operation", newJString(operation))
  result = call_605483.call(path_605484, query_605485, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_605470(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_605471, base: "/",
    url: url_RestorePhoneNumber_605472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_605486 = ref object of OpenApiRestCall_603389
proc url_SearchAvailablePhoneNumbers_605488(protocol: Scheme; host: string;
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

proc validate_SearchAvailablePhoneNumbers_605487(path: JsonNode; query: JsonNode;
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
  var valid_605489 = query.getOrDefault("state")
  valid_605489 = validateParameter(valid_605489, JString, required = false,
                                 default = nil)
  if valid_605489 != nil:
    section.add "state", valid_605489
  var valid_605490 = query.getOrDefault("area-code")
  valid_605490 = validateParameter(valid_605490, JString, required = false,
                                 default = nil)
  if valid_605490 != nil:
    section.add "area-code", valid_605490
  var valid_605491 = query.getOrDefault("toll-free-prefix")
  valid_605491 = validateParameter(valid_605491, JString, required = false,
                                 default = nil)
  if valid_605491 != nil:
    section.add "toll-free-prefix", valid_605491
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_605492 = query.getOrDefault("type")
  valid_605492 = validateParameter(valid_605492, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_605492 != nil:
    section.add "type", valid_605492
  var valid_605493 = query.getOrDefault("city")
  valid_605493 = validateParameter(valid_605493, JString, required = false,
                                 default = nil)
  if valid_605493 != nil:
    section.add "city", valid_605493
  var valid_605494 = query.getOrDefault("country")
  valid_605494 = validateParameter(valid_605494, JString, required = false,
                                 default = nil)
  if valid_605494 != nil:
    section.add "country", valid_605494
  var valid_605495 = query.getOrDefault("max-results")
  valid_605495 = validateParameter(valid_605495, JInt, required = false, default = nil)
  if valid_605495 != nil:
    section.add "max-results", valid_605495
  var valid_605496 = query.getOrDefault("next-token")
  valid_605496 = validateParameter(valid_605496, JString, required = false,
                                 default = nil)
  if valid_605496 != nil:
    section.add "next-token", valid_605496
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605497 = header.getOrDefault("X-Amz-Signature")
  valid_605497 = validateParameter(valid_605497, JString, required = false,
                                 default = nil)
  if valid_605497 != nil:
    section.add "X-Amz-Signature", valid_605497
  var valid_605498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605498 = validateParameter(valid_605498, JString, required = false,
                                 default = nil)
  if valid_605498 != nil:
    section.add "X-Amz-Content-Sha256", valid_605498
  var valid_605499 = header.getOrDefault("X-Amz-Date")
  valid_605499 = validateParameter(valid_605499, JString, required = false,
                                 default = nil)
  if valid_605499 != nil:
    section.add "X-Amz-Date", valid_605499
  var valid_605500 = header.getOrDefault("X-Amz-Credential")
  valid_605500 = validateParameter(valid_605500, JString, required = false,
                                 default = nil)
  if valid_605500 != nil:
    section.add "X-Amz-Credential", valid_605500
  var valid_605501 = header.getOrDefault("X-Amz-Security-Token")
  valid_605501 = validateParameter(valid_605501, JString, required = false,
                                 default = nil)
  if valid_605501 != nil:
    section.add "X-Amz-Security-Token", valid_605501
  var valid_605502 = header.getOrDefault("X-Amz-Algorithm")
  valid_605502 = validateParameter(valid_605502, JString, required = false,
                                 default = nil)
  if valid_605502 != nil:
    section.add "X-Amz-Algorithm", valid_605502
  var valid_605503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605503 = validateParameter(valid_605503, JString, required = false,
                                 default = nil)
  if valid_605503 != nil:
    section.add "X-Amz-SignedHeaders", valid_605503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605504: Call_SearchAvailablePhoneNumbers_605486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_605504.validator(path, query, header, formData, body)
  let scheme = call_605504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605504.url(scheme.get, call_605504.host, call_605504.base,
                         call_605504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605504, url, valid)

proc call*(call_605505: Call_SearchAvailablePhoneNumbers_605486;
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
  var query_605506 = newJObject()
  add(query_605506, "state", newJString(state))
  add(query_605506, "area-code", newJString(areaCode))
  add(query_605506, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_605506, "type", newJString(`type`))
  add(query_605506, "city", newJString(city))
  add(query_605506, "country", newJString(country))
  add(query_605506, "max-results", newJInt(maxResults))
  add(query_605506, "next-token", newJString(nextToken))
  result = call_605505.call(nil, query_605506, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_605486(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_605487, base: "/",
    url: url_SearchAvailablePhoneNumbers_605488,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
