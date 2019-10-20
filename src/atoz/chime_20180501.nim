
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociatePhoneNumberWithUser_592703 = ref object of OpenApiRestCall_592364
proc url_AssociatePhoneNumberWithUser_592705(protocol: Scheme; host: string;
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

proc validate_AssociatePhoneNumberWithUser_592704(path: JsonNode; query: JsonNode;
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
  var valid_592831 = path.getOrDefault("userId")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "userId", valid_592831
  var valid_592832 = path.getOrDefault("accountId")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = nil)
  if valid_592832 != nil:
    section.add "accountId", valid_592832
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_592846 = query.getOrDefault("operation")
  valid_592846 = validateParameter(valid_592846, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_592846 != nil:
    section.add "operation", valid_592846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592847 = header.getOrDefault("X-Amz-Signature")
  valid_592847 = validateParameter(valid_592847, JString, required = false,
                                 default = nil)
  if valid_592847 != nil:
    section.add "X-Amz-Signature", valid_592847
  var valid_592848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592848 = validateParameter(valid_592848, JString, required = false,
                                 default = nil)
  if valid_592848 != nil:
    section.add "X-Amz-Content-Sha256", valid_592848
  var valid_592849 = header.getOrDefault("X-Amz-Date")
  valid_592849 = validateParameter(valid_592849, JString, required = false,
                                 default = nil)
  if valid_592849 != nil:
    section.add "X-Amz-Date", valid_592849
  var valid_592850 = header.getOrDefault("X-Amz-Credential")
  valid_592850 = validateParameter(valid_592850, JString, required = false,
                                 default = nil)
  if valid_592850 != nil:
    section.add "X-Amz-Credential", valid_592850
  var valid_592851 = header.getOrDefault("X-Amz-Security-Token")
  valid_592851 = validateParameter(valid_592851, JString, required = false,
                                 default = nil)
  if valid_592851 != nil:
    section.add "X-Amz-Security-Token", valid_592851
  var valid_592852 = header.getOrDefault("X-Amz-Algorithm")
  valid_592852 = validateParameter(valid_592852, JString, required = false,
                                 default = nil)
  if valid_592852 != nil:
    section.add "X-Amz-Algorithm", valid_592852
  var valid_592853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592853 = validateParameter(valid_592853, JString, required = false,
                                 default = nil)
  if valid_592853 != nil:
    section.add "X-Amz-SignedHeaders", valid_592853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592877: Call_AssociatePhoneNumberWithUser_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_592877.validator(path, query, header, formData, body)
  let scheme = call_592877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592877.url(scheme.get, call_592877.host, call_592877.base,
                         call_592877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592877, url, valid)

proc call*(call_592948: Call_AssociatePhoneNumberWithUser_592703; userId: string;
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
  var path_592949 = newJObject()
  var query_592951 = newJObject()
  var body_592952 = newJObject()
  add(query_592951, "operation", newJString(operation))
  add(path_592949, "userId", newJString(userId))
  if body != nil:
    body_592952 = body
  add(path_592949, "accountId", newJString(accountId))
  result = call_592948.call(path_592949, query_592951, nil, nil, body_592952)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_592703(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_592704, base: "/",
    url: url_AssociatePhoneNumberWithUser_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_592991 = ref object of OpenApiRestCall_592364
proc url_AssociatePhoneNumbersWithVoiceConnector_592993(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnector_592992(path: JsonNode;
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
  var valid_592994 = path.getOrDefault("voiceConnectorId")
  valid_592994 = validateParameter(valid_592994, JString, required = true,
                                 default = nil)
  if valid_592994 != nil:
    section.add "voiceConnectorId", valid_592994
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_592995 = query.getOrDefault("operation")
  valid_592995 = validateParameter(valid_592995, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_592995 != nil:
    section.add "operation", valid_592995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592996 = header.getOrDefault("X-Amz-Signature")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Signature", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Content-Sha256", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Date")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Date", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Credential")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Credential", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Security-Token")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Security-Token", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Algorithm")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Algorithm", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-SignedHeaders", valid_593002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593004: Call_AssociatePhoneNumbersWithVoiceConnector_592991;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593004.validator(path, query, header, formData, body)
  let scheme = call_593004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593004.url(scheme.get, call_593004.host, call_593004.base,
                         call_593004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593004, url, valid)

proc call*(call_593005: Call_AssociatePhoneNumbersWithVoiceConnector_592991;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_593006 = newJObject()
  var query_593007 = newJObject()
  var body_593008 = newJObject()
  add(query_593007, "operation", newJString(operation))
  add(path_593006, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_593008 = body
  result = call_593005.call(path_593006, query_593007, nil, nil, body_593008)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_592991(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_592992, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_592993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_593009 = ref object of OpenApiRestCall_592364
proc url_BatchDeletePhoneNumber_593011(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeletePhoneNumber_593010(path: JsonNode; query: JsonNode;
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
  var valid_593012 = query.getOrDefault("operation")
  valid_593012 = validateParameter(valid_593012, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_593012 != nil:
    section.add "operation", valid_593012
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593013 = header.getOrDefault("X-Amz-Signature")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Signature", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Content-Sha256", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Date")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Date", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Credential")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Credential", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Security-Token")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Security-Token", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Algorithm")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Algorithm", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-SignedHeaders", valid_593019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593021: Call_BatchDeletePhoneNumber_593009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_593021.validator(path, query, header, formData, body)
  let scheme = call_593021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593021.url(scheme.get, call_593021.host, call_593021.base,
                         call_593021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593021, url, valid)

proc call*(call_593022: Call_BatchDeletePhoneNumber_593009; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_593023 = newJObject()
  var body_593024 = newJObject()
  add(query_593023, "operation", newJString(operation))
  if body != nil:
    body_593024 = body
  result = call_593022.call(nil, query_593023, nil, nil, body_593024)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_593009(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_593010, base: "/",
    url: url_BatchDeletePhoneNumber_593011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_593025 = ref object of OpenApiRestCall_592364
proc url_BatchSuspendUser_593027(protocol: Scheme; host: string; base: string;
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

proc validate_BatchSuspendUser_593026(path: JsonNode; query: JsonNode;
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
  var valid_593028 = path.getOrDefault("accountId")
  valid_593028 = validateParameter(valid_593028, JString, required = true,
                                 default = nil)
  if valid_593028 != nil:
    section.add "accountId", valid_593028
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593029 = query.getOrDefault("operation")
  valid_593029 = validateParameter(valid_593029, JString, required = true,
                                 default = newJString("suspend"))
  if valid_593029 != nil:
    section.add "operation", valid_593029
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593030 = header.getOrDefault("X-Amz-Signature")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Signature", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Content-Sha256", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Date")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Date", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Credential")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Credential", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Security-Token")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Security-Token", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Algorithm")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Algorithm", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-SignedHeaders", valid_593036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593038: Call_BatchSuspendUser_593025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_593038.validator(path, query, header, formData, body)
  let scheme = call_593038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593038.url(scheme.get, call_593038.host, call_593038.base,
                         call_593038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593038, url, valid)

proc call*(call_593039: Call_BatchSuspendUser_593025; body: JsonNode;
          accountId: string; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593040 = newJObject()
  var query_593041 = newJObject()
  var body_593042 = newJObject()
  add(query_593041, "operation", newJString(operation))
  if body != nil:
    body_593042 = body
  add(path_593040, "accountId", newJString(accountId))
  result = call_593039.call(path_593040, query_593041, nil, nil, body_593042)

var batchSuspendUser* = Call_BatchSuspendUser_593025(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_593026, base: "/",
    url: url_BatchSuspendUser_593027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_593043 = ref object of OpenApiRestCall_592364
proc url_BatchUnsuspendUser_593045(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUnsuspendUser_593044(path: JsonNode; query: JsonNode;
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
  var valid_593046 = path.getOrDefault("accountId")
  valid_593046 = validateParameter(valid_593046, JString, required = true,
                                 default = nil)
  if valid_593046 != nil:
    section.add "accountId", valid_593046
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593047 = query.getOrDefault("operation")
  valid_593047 = validateParameter(valid_593047, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_593047 != nil:
    section.add "operation", valid_593047
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593048 = header.getOrDefault("X-Amz-Signature")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Signature", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Content-Sha256", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Date")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Date", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Credential")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Credential", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Security-Token")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Security-Token", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Algorithm")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Algorithm", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-SignedHeaders", valid_593054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593056: Call_BatchUnsuspendUser_593043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_593056.validator(path, query, header, formData, body)
  let scheme = call_593056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593056.url(scheme.get, call_593056.host, call_593056.base,
                         call_593056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593056, url, valid)

proc call*(call_593057: Call_BatchUnsuspendUser_593043; body: JsonNode;
          accountId: string; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593058 = newJObject()
  var query_593059 = newJObject()
  var body_593060 = newJObject()
  add(query_593059, "operation", newJString(operation))
  if body != nil:
    body_593060 = body
  add(path_593058, "accountId", newJString(accountId))
  result = call_593057.call(path_593058, query_593059, nil, nil, body_593060)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_593043(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_593044, base: "/",
    url: url_BatchUnsuspendUser_593045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_593061 = ref object of OpenApiRestCall_592364
proc url_BatchUpdatePhoneNumber_593063(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchUpdatePhoneNumber_593062(path: JsonNode; query: JsonNode;
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
  var valid_593064 = query.getOrDefault("operation")
  valid_593064 = validateParameter(valid_593064, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_593064 != nil:
    section.add "operation", valid_593064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593065 = header.getOrDefault("X-Amz-Signature")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Signature", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Content-Sha256", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Date")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Date", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Credential")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Credential", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Security-Token")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Security-Token", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Algorithm")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Algorithm", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-SignedHeaders", valid_593071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593073: Call_BatchUpdatePhoneNumber_593061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_593073.validator(path, query, header, formData, body)
  let scheme = call_593073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593073.url(scheme.get, call_593073.host, call_593073.base,
                         call_593073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593073, url, valid)

proc call*(call_593074: Call_BatchUpdatePhoneNumber_593061; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_593075 = newJObject()
  var body_593076 = newJObject()
  add(query_593075, "operation", newJString(operation))
  if body != nil:
    body_593076 = body
  result = call_593074.call(nil, query_593075, nil, nil, body_593076)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_593061(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_593062, base: "/",
    url: url_BatchUpdatePhoneNumber_593063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_593097 = ref object of OpenApiRestCall_592364
proc url_BatchUpdateUser_593099(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateUser_593098(path: JsonNode; query: JsonNode;
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
  var valid_593100 = path.getOrDefault("accountId")
  valid_593100 = validateParameter(valid_593100, JString, required = true,
                                 default = nil)
  if valid_593100 != nil:
    section.add "accountId", valid_593100
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
  var valid_593101 = header.getOrDefault("X-Amz-Signature")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Signature", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Content-Sha256", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Date")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Date", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Credential")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Credential", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Security-Token")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Security-Token", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Algorithm")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Algorithm", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-SignedHeaders", valid_593107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593109: Call_BatchUpdateUser_593097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_593109.validator(path, query, header, formData, body)
  let scheme = call_593109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593109.url(scheme.get, call_593109.host, call_593109.base,
                         call_593109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593109, url, valid)

proc call*(call_593110: Call_BatchUpdateUser_593097; body: JsonNode;
          accountId: string): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593111 = newJObject()
  var body_593112 = newJObject()
  if body != nil:
    body_593112 = body
  add(path_593111, "accountId", newJString(accountId))
  result = call_593110.call(path_593111, nil, nil, nil, body_593112)

var batchUpdateUser* = Call_BatchUpdateUser_593097(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_593098,
    base: "/", url: url_BatchUpdateUser_593099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_593077 = ref object of OpenApiRestCall_592364
proc url_ListUsers_593079(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_593078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593080 = path.getOrDefault("accountId")
  valid_593080 = validateParameter(valid_593080, JString, required = true,
                                 default = nil)
  if valid_593080 != nil:
    section.add "accountId", valid_593080
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   user-email: JString
  ##             : Optional. The user email address used to filter results. Maximum 1.
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Defaults to 100.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_593081 = query.getOrDefault("MaxResults")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "MaxResults", valid_593081
  var valid_593082 = query.getOrDefault("user-email")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "user-email", valid_593082
  var valid_593083 = query.getOrDefault("NextToken")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "NextToken", valid_593083
  var valid_593084 = query.getOrDefault("max-results")
  valid_593084 = validateParameter(valid_593084, JInt, required = false, default = nil)
  if valid_593084 != nil:
    section.add "max-results", valid_593084
  var valid_593085 = query.getOrDefault("next-token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "next-token", valid_593085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593086 = header.getOrDefault("X-Amz-Signature")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Signature", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Content-Sha256", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Date")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Date", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Credential")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Credential", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Security-Token")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Security-Token", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Algorithm")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Algorithm", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-SignedHeaders", valid_593092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593093: Call_ListUsers_593077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_593093.validator(path, query, header, formData, body)
  let scheme = call_593093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593093.url(scheme.get, call_593093.host, call_593093.base,
                         call_593093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593093, url, valid)

proc call*(call_593094: Call_ListUsers_593077; accountId: string;
          MaxResults: string = ""; userEmail: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   userEmail: string
  ##            : Optional. The user email address used to filter results. Maximum 1.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Defaults to 100.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_593095 = newJObject()
  var query_593096 = newJObject()
  add(query_593096, "MaxResults", newJString(MaxResults))
  add(query_593096, "user-email", newJString(userEmail))
  add(query_593096, "NextToken", newJString(NextToken))
  add(query_593096, "max-results", newJInt(maxResults))
  add(path_593095, "accountId", newJString(accountId))
  add(query_593096, "next-token", newJString(nextToken))
  result = call_593094.call(path_593095, query_593096, nil, nil, nil)

var listUsers* = Call_ListUsers_593077(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_593078,
                                    base: "/", url: url_ListUsers_593079,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_593132 = ref object of OpenApiRestCall_592364
proc url_CreateAccount_593134(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAccount_593133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593135 = header.getOrDefault("X-Amz-Signature")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Signature", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Content-Sha256", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Date")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Date", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Credential")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Credential", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Security-Token")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Security-Token", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Algorithm")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Algorithm", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-SignedHeaders", valid_593141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593143: Call_CreateAccount_593132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_593143.validator(path, query, header, formData, body)
  let scheme = call_593143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593143.url(scheme.get, call_593143.host, call_593143.base,
                         call_593143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593143, url, valid)

proc call*(call_593144: Call_CreateAccount_593132; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_593145 = newJObject()
  if body != nil:
    body_593145 = body
  result = call_593144.call(nil, nil, nil, nil, body_593145)

var createAccount* = Call_CreateAccount_593132(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_593133, base: "/", url: url_CreateAccount_593134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_593113 = ref object of OpenApiRestCall_592364
proc url_ListAccounts_593115(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAccounts_593114(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593116 = query.getOrDefault("name")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "name", valid_593116
  var valid_593117 = query.getOrDefault("MaxResults")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "MaxResults", valid_593117
  var valid_593118 = query.getOrDefault("user-email")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "user-email", valid_593118
  var valid_593119 = query.getOrDefault("NextToken")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "NextToken", valid_593119
  var valid_593120 = query.getOrDefault("max-results")
  valid_593120 = validateParameter(valid_593120, JInt, required = false, default = nil)
  if valid_593120 != nil:
    section.add "max-results", valid_593120
  var valid_593121 = query.getOrDefault("next-token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "next-token", valid_593121
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593122 = header.getOrDefault("X-Amz-Signature")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Signature", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Content-Sha256", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Date")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Date", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Credential")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Credential", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Security-Token")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Security-Token", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Algorithm")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Algorithm", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-SignedHeaders", valid_593128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593129: Call_ListAccounts_593113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_593129.validator(path, query, header, formData, body)
  let scheme = call_593129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593129.url(scheme.get, call_593129.host, call_593129.base,
                         call_593129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593129, url, valid)

proc call*(call_593130: Call_ListAccounts_593113; name: string = "";
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
  var query_593131 = newJObject()
  add(query_593131, "name", newJString(name))
  add(query_593131, "MaxResults", newJString(MaxResults))
  add(query_593131, "user-email", newJString(userEmail))
  add(query_593131, "NextToken", newJString(NextToken))
  add(query_593131, "max-results", newJInt(maxResults))
  add(query_593131, "next-token", newJString(nextToken))
  result = call_593130.call(nil, query_593131, nil, nil, nil)

var listAccounts* = Call_ListAccounts_593113(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_593114, base: "/", url: url_ListAccounts_593115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_593163 = ref object of OpenApiRestCall_592364
proc url_CreateBot_593165(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateBot_593164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593166 = path.getOrDefault("accountId")
  valid_593166 = validateParameter(valid_593166, JString, required = true,
                                 default = nil)
  if valid_593166 != nil:
    section.add "accountId", valid_593166
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
  var valid_593167 = header.getOrDefault("X-Amz-Signature")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Signature", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Content-Sha256", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Date")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Date", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Credential")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Credential", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Security-Token")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Security-Token", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Algorithm")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Algorithm", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-SignedHeaders", valid_593173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593175: Call_CreateBot_593163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_593175.validator(path, query, header, formData, body)
  let scheme = call_593175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593175.url(scheme.get, call_593175.host, call_593175.base,
                         call_593175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593175, url, valid)

proc call*(call_593176: Call_CreateBot_593163; body: JsonNode; accountId: string): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593177 = newJObject()
  var body_593178 = newJObject()
  if body != nil:
    body_593178 = body
  add(path_593177, "accountId", newJString(accountId))
  result = call_593176.call(path_593177, nil, nil, nil, body_593178)

var createBot* = Call_CreateBot_593163(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_593164,
                                    base: "/", url: url_CreateBot_593165,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_593146 = ref object of OpenApiRestCall_592364
proc url_ListBots_593148(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListBots_593147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593149 = path.getOrDefault("accountId")
  valid_593149 = validateParameter(valid_593149, JString, required = true,
                                 default = nil)
  if valid_593149 != nil:
    section.add "accountId", valid_593149
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Default is 10.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_593150 = query.getOrDefault("max-results")
  valid_593150 = validateParameter(valid_593150, JInt, required = false, default = nil)
  if valid_593150 != nil:
    section.add "max-results", valid_593150
  var valid_593151 = query.getOrDefault("next-token")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "next-token", valid_593151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593152 = header.getOrDefault("X-Amz-Signature")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Signature", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Content-Sha256", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Date")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Date", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Credential")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Credential", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Security-Token")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Security-Token", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Algorithm")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Algorithm", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-SignedHeaders", valid_593158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593159: Call_ListBots_593146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_593159.validator(path, query, header, formData, body)
  let scheme = call_593159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593159.url(scheme.get, call_593159.host, call_593159.base,
                         call_593159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593159, url, valid)

proc call*(call_593160: Call_ListBots_593146; accountId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBots
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Default is 10.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_593161 = newJObject()
  var query_593162 = newJObject()
  add(query_593162, "max-results", newJInt(maxResults))
  add(path_593161, "accountId", newJString(accountId))
  add(query_593162, "next-token", newJString(nextToken))
  result = call_593160.call(path_593161, query_593162, nil, nil, nil)

var listBots* = Call_ListBots_593146(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_593147, base: "/",
                                  url: url_ListBots_593148,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_593196 = ref object of OpenApiRestCall_592364
proc url_CreatePhoneNumberOrder_593198(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePhoneNumberOrder_593197(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593199 = header.getOrDefault("X-Amz-Signature")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Signature", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Content-Sha256", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Date")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Date", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Credential")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Credential", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Security-Token")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Security-Token", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Algorithm")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Algorithm", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-SignedHeaders", valid_593205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593207: Call_CreatePhoneNumberOrder_593196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_593207.validator(path, query, header, formData, body)
  let scheme = call_593207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593207.url(scheme.get, call_593207.host, call_593207.base,
                         call_593207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593207, url, valid)

proc call*(call_593208: Call_CreatePhoneNumberOrder_593196; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_593209 = newJObject()
  if body != nil:
    body_593209 = body
  result = call_593208.call(nil, nil, nil, nil, body_593209)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_593196(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_593197, base: "/",
    url: url_CreatePhoneNumberOrder_593198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_593179 = ref object of OpenApiRestCall_592364
proc url_ListPhoneNumberOrders_593181(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPhoneNumberOrders_593180(path: JsonNode; query: JsonNode;
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
  var valid_593182 = query.getOrDefault("MaxResults")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "MaxResults", valid_593182
  var valid_593183 = query.getOrDefault("NextToken")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "NextToken", valid_593183
  var valid_593184 = query.getOrDefault("max-results")
  valid_593184 = validateParameter(valid_593184, JInt, required = false, default = nil)
  if valid_593184 != nil:
    section.add "max-results", valid_593184
  var valid_593185 = query.getOrDefault("next-token")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "next-token", valid_593185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593186 = header.getOrDefault("X-Amz-Signature")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Signature", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Content-Sha256", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Date")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Date", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Credential")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Credential", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Security-Token")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Security-Token", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Algorithm")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Algorithm", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-SignedHeaders", valid_593192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593193: Call_ListPhoneNumberOrders_593179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_593193.validator(path, query, header, formData, body)
  let scheme = call_593193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593193.url(scheme.get, call_593193.host, call_593193.base,
                         call_593193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593193, url, valid)

proc call*(call_593194: Call_ListPhoneNumberOrders_593179; MaxResults: string = "";
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
  var query_593195 = newJObject()
  add(query_593195, "MaxResults", newJString(MaxResults))
  add(query_593195, "NextToken", newJString(NextToken))
  add(query_593195, "max-results", newJInt(maxResults))
  add(query_593195, "next-token", newJString(nextToken))
  result = call_593194.call(nil, query_593195, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_593179(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_593180, base: "/",
    url: url_ListPhoneNumberOrders_593181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_593227 = ref object of OpenApiRestCall_592364
proc url_CreateVoiceConnector_593229(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVoiceConnector_593228(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593230 = header.getOrDefault("X-Amz-Signature")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Signature", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Content-Sha256", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Date")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Date", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Credential")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Credential", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Security-Token")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Security-Token", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Algorithm")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Algorithm", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-SignedHeaders", valid_593236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593238: Call_CreateVoiceConnector_593227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ## 
  let valid = call_593238.validator(path, query, header, formData, body)
  let scheme = call_593238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593238.url(scheme.get, call_593238.host, call_593238.base,
                         call_593238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593238, url, valid)

proc call*(call_593239: Call_CreateVoiceConnector_593227; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ##   body: JObject (required)
  var body_593240 = newJObject()
  if body != nil:
    body_593240 = body
  result = call_593239.call(nil, nil, nil, nil, body_593240)

var createVoiceConnector* = Call_CreateVoiceConnector_593227(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_593228, base: "/",
    url: url_CreateVoiceConnector_593229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_593210 = ref object of OpenApiRestCall_592364
proc url_ListVoiceConnectors_593212(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVoiceConnectors_593211(path: JsonNode; query: JsonNode;
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
  var valid_593213 = query.getOrDefault("MaxResults")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "MaxResults", valid_593213
  var valid_593214 = query.getOrDefault("NextToken")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "NextToken", valid_593214
  var valid_593215 = query.getOrDefault("max-results")
  valid_593215 = validateParameter(valid_593215, JInt, required = false, default = nil)
  if valid_593215 != nil:
    section.add "max-results", valid_593215
  var valid_593216 = query.getOrDefault("next-token")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "next-token", valid_593216
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593217 = header.getOrDefault("X-Amz-Signature")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Signature", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Content-Sha256", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Date")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Date", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Credential")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Credential", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Security-Token")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Security-Token", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Algorithm")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Algorithm", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-SignedHeaders", valid_593223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593224: Call_ListVoiceConnectors_593210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_593224.validator(path, query, header, formData, body)
  let scheme = call_593224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593224.url(scheme.get, call_593224.host, call_593224.base,
                         call_593224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593224, url, valid)

proc call*(call_593225: Call_ListVoiceConnectors_593210; MaxResults: string = "";
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
  var query_593226 = newJObject()
  add(query_593226, "MaxResults", newJString(MaxResults))
  add(query_593226, "NextToken", newJString(NextToken))
  add(query_593226, "max-results", newJInt(maxResults))
  add(query_593226, "next-token", newJString(nextToken))
  result = call_593225.call(nil, query_593226, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_593210(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_593211, base: "/",
    url: url_ListVoiceConnectors_593212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_593255 = ref object of OpenApiRestCall_592364
proc url_UpdateAccount_593257(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_593256(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593258 = path.getOrDefault("accountId")
  valid_593258 = validateParameter(valid_593258, JString, required = true,
                                 default = nil)
  if valid_593258 != nil:
    section.add "accountId", valid_593258
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
  var valid_593259 = header.getOrDefault("X-Amz-Signature")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Signature", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Content-Sha256", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Date")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Date", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Credential")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Credential", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Security-Token")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Security-Token", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Algorithm")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Algorithm", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-SignedHeaders", valid_593265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593267: Call_UpdateAccount_593255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_593267.validator(path, query, header, formData, body)
  let scheme = call_593267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593267.url(scheme.get, call_593267.host, call_593267.base,
                         call_593267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593267, url, valid)

proc call*(call_593268: Call_UpdateAccount_593255; body: JsonNode; accountId: string): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593269 = newJObject()
  var body_593270 = newJObject()
  if body != nil:
    body_593270 = body
  add(path_593269, "accountId", newJString(accountId))
  result = call_593268.call(path_593269, nil, nil, nil, body_593270)

var updateAccount* = Call_UpdateAccount_593255(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_593256,
    base: "/", url: url_UpdateAccount_593257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_593241 = ref object of OpenApiRestCall_592364
proc url_GetAccount_593243(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_593242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593244 = path.getOrDefault("accountId")
  valid_593244 = validateParameter(valid_593244, JString, required = true,
                                 default = nil)
  if valid_593244 != nil:
    section.add "accountId", valid_593244
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
  var valid_593245 = header.getOrDefault("X-Amz-Signature")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Signature", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Content-Sha256", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Date")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Date", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Credential")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Credential", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Security-Token")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Security-Token", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Algorithm")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Algorithm", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-SignedHeaders", valid_593251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593252: Call_GetAccount_593241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_593252.validator(path, query, header, formData, body)
  let scheme = call_593252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593252.url(scheme.get, call_593252.host, call_593252.base,
                         call_593252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593252, url, valid)

proc call*(call_593253: Call_GetAccount_593241; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593254 = newJObject()
  add(path_593254, "accountId", newJString(accountId))
  result = call_593253.call(path_593254, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_593241(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_593242,
                                      base: "/", url: url_GetAccount_593243,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_593271 = ref object of OpenApiRestCall_592364
proc url_DeleteAccount_593273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccount_593272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593274 = path.getOrDefault("accountId")
  valid_593274 = validateParameter(valid_593274, JString, required = true,
                                 default = nil)
  if valid_593274 != nil:
    section.add "accountId", valid_593274
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
  var valid_593275 = header.getOrDefault("X-Amz-Signature")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Signature", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Content-Sha256", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Date")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Date", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Credential")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Credential", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Security-Token")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Security-Token", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Algorithm")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Algorithm", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-SignedHeaders", valid_593281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593282: Call_DeleteAccount_593271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_593282.validator(path, query, header, formData, body)
  let scheme = call_593282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593282.url(scheme.get, call_593282.host, call_593282.base,
                         call_593282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593282, url, valid)

proc call*(call_593283: Call_DeleteAccount_593271; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593284 = newJObject()
  add(path_593284, "accountId", newJString(accountId))
  result = call_593283.call(path_593284, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_593271(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_593272,
    base: "/", url: url_DeleteAccount_593273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_593300 = ref object of OpenApiRestCall_592364
proc url_PutEventsConfiguration_593302(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventsConfiguration_593301(path: JsonNode; query: JsonNode;
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
  var valid_593303 = path.getOrDefault("botId")
  valid_593303 = validateParameter(valid_593303, JString, required = true,
                                 default = nil)
  if valid_593303 != nil:
    section.add "botId", valid_593303
  var valid_593304 = path.getOrDefault("accountId")
  valid_593304 = validateParameter(valid_593304, JString, required = true,
                                 default = nil)
  if valid_593304 != nil:
    section.add "accountId", valid_593304
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
  var valid_593305 = header.getOrDefault("X-Amz-Signature")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Signature", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Content-Sha256", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Date")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Date", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Credential")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Credential", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Security-Token")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Security-Token", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Algorithm")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Algorithm", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-SignedHeaders", valid_593311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593313: Call_PutEventsConfiguration_593300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_593313.validator(path, query, header, formData, body)
  let scheme = call_593313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593313.url(scheme.get, call_593313.host, call_593313.base,
                         call_593313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593313, url, valid)

proc call*(call_593314: Call_PutEventsConfiguration_593300; botId: string;
          body: JsonNode; accountId: string): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593315 = newJObject()
  var body_593316 = newJObject()
  add(path_593315, "botId", newJString(botId))
  if body != nil:
    body_593316 = body
  add(path_593315, "accountId", newJString(accountId))
  result = call_593314.call(path_593315, nil, nil, nil, body_593316)

var putEventsConfiguration* = Call_PutEventsConfiguration_593300(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_593301, base: "/",
    url: url_PutEventsConfiguration_593302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_593285 = ref object of OpenApiRestCall_592364
proc url_GetEventsConfiguration_593287(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventsConfiguration_593286(path: JsonNode; query: JsonNode;
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
  var valid_593288 = path.getOrDefault("botId")
  valid_593288 = validateParameter(valid_593288, JString, required = true,
                                 default = nil)
  if valid_593288 != nil:
    section.add "botId", valid_593288
  var valid_593289 = path.getOrDefault("accountId")
  valid_593289 = validateParameter(valid_593289, JString, required = true,
                                 default = nil)
  if valid_593289 != nil:
    section.add "accountId", valid_593289
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
  var valid_593290 = header.getOrDefault("X-Amz-Signature")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Signature", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Content-Sha256", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Date")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Date", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Credential")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Credential", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Security-Token")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Security-Token", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Algorithm")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Algorithm", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-SignedHeaders", valid_593296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593297: Call_GetEventsConfiguration_593285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_593297.validator(path, query, header, formData, body)
  let scheme = call_593297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593297.url(scheme.get, call_593297.host, call_593297.base,
                         call_593297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593297, url, valid)

proc call*(call_593298: Call_GetEventsConfiguration_593285; botId: string;
          accountId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593299 = newJObject()
  add(path_593299, "botId", newJString(botId))
  add(path_593299, "accountId", newJString(accountId))
  result = call_593298.call(path_593299, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_593285(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_593286, base: "/",
    url: url_GetEventsConfiguration_593287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_593317 = ref object of OpenApiRestCall_592364
proc url_DeleteEventsConfiguration_593319(protocol: Scheme; host: string;
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

proc validate_DeleteEventsConfiguration_593318(path: JsonNode; query: JsonNode;
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
  var valid_593320 = path.getOrDefault("botId")
  valid_593320 = validateParameter(valid_593320, JString, required = true,
                                 default = nil)
  if valid_593320 != nil:
    section.add "botId", valid_593320
  var valid_593321 = path.getOrDefault("accountId")
  valid_593321 = validateParameter(valid_593321, JString, required = true,
                                 default = nil)
  if valid_593321 != nil:
    section.add "accountId", valid_593321
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
  var valid_593322 = header.getOrDefault("X-Amz-Signature")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Signature", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Content-Sha256", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Date")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Date", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Credential")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Credential", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Security-Token")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Security-Token", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Algorithm")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Algorithm", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-SignedHeaders", valid_593328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593329: Call_DeleteEventsConfiguration_593317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_DeleteEventsConfiguration_593317; botId: string;
          accountId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593331 = newJObject()
  add(path_593331, "botId", newJString(botId))
  add(path_593331, "accountId", newJString(accountId))
  result = call_593330.call(path_593331, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_593317(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_593318, base: "/",
    url: url_DeleteEventsConfiguration_593319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_593346 = ref object of OpenApiRestCall_592364
proc url_UpdatePhoneNumber_593348(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePhoneNumber_593347(path: JsonNode; query: JsonNode;
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
  var valid_593349 = path.getOrDefault("phoneNumberId")
  valid_593349 = validateParameter(valid_593349, JString, required = true,
                                 default = nil)
  if valid_593349 != nil:
    section.add "phoneNumberId", valid_593349
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
  var valid_593350 = header.getOrDefault("X-Amz-Signature")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Signature", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Content-Sha256", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Date")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Date", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Credential")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Credential", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Security-Token")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Security-Token", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Algorithm")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Algorithm", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-SignedHeaders", valid_593356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593358: Call_UpdatePhoneNumber_593346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_593358.validator(path, query, header, formData, body)
  let scheme = call_593358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593358.url(scheme.get, call_593358.host, call_593358.base,
                         call_593358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593358, url, valid)

proc call*(call_593359: Call_UpdatePhoneNumber_593346; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_593360 = newJObject()
  var body_593361 = newJObject()
  add(path_593360, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_593361 = body
  result = call_593359.call(path_593360, nil, nil, nil, body_593361)

var updatePhoneNumber* = Call_UpdatePhoneNumber_593346(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_593347, base: "/",
    url: url_UpdatePhoneNumber_593348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_593332 = ref object of OpenApiRestCall_592364
proc url_GetPhoneNumber_593334(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumber_593333(path: JsonNode; query: JsonNode;
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
  var valid_593335 = path.getOrDefault("phoneNumberId")
  valid_593335 = validateParameter(valid_593335, JString, required = true,
                                 default = nil)
  if valid_593335 != nil:
    section.add "phoneNumberId", valid_593335
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
  var valid_593336 = header.getOrDefault("X-Amz-Signature")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Signature", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Content-Sha256", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Date")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Date", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Credential")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Credential", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Security-Token")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Security-Token", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Algorithm")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Algorithm", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-SignedHeaders", valid_593342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593343: Call_GetPhoneNumber_593332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_593343.validator(path, query, header, formData, body)
  let scheme = call_593343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593343.url(scheme.get, call_593343.host, call_593343.base,
                         call_593343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593343, url, valid)

proc call*(call_593344: Call_GetPhoneNumber_593332; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_593345 = newJObject()
  add(path_593345, "phoneNumberId", newJString(phoneNumberId))
  result = call_593344.call(path_593345, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_593332(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_593333,
    base: "/", url: url_GetPhoneNumber_593334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_593362 = ref object of OpenApiRestCall_592364
proc url_DeletePhoneNumber_593364(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePhoneNumber_593363(path: JsonNode; query: JsonNode;
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
  var valid_593365 = path.getOrDefault("phoneNumberId")
  valid_593365 = validateParameter(valid_593365, JString, required = true,
                                 default = nil)
  if valid_593365 != nil:
    section.add "phoneNumberId", valid_593365
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
  var valid_593366 = header.getOrDefault("X-Amz-Signature")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Signature", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Content-Sha256", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Date")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Date", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Credential")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Credential", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Security-Token")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Security-Token", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Algorithm")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Algorithm", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-SignedHeaders", valid_593372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593373: Call_DeletePhoneNumber_593362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_593373.validator(path, query, header, formData, body)
  let scheme = call_593373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593373.url(scheme.get, call_593373.host, call_593373.base,
                         call_593373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593373, url, valid)

proc call*(call_593374: Call_DeletePhoneNumber_593362; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_593375 = newJObject()
  add(path_593375, "phoneNumberId", newJString(phoneNumberId))
  result = call_593374.call(path_593375, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_593362(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_593363, base: "/",
    url: url_DeletePhoneNumber_593364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_593390 = ref object of OpenApiRestCall_592364
proc url_UpdateVoiceConnector_593392(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceConnector_593391(path: JsonNode; query: JsonNode;
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
  var valid_593393 = path.getOrDefault("voiceConnectorId")
  valid_593393 = validateParameter(valid_593393, JString, required = true,
                                 default = nil)
  if valid_593393 != nil:
    section.add "voiceConnectorId", valid_593393
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
  var valid_593394 = header.getOrDefault("X-Amz-Signature")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Signature", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Content-Sha256", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Date")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Date", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Credential")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Credential", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Security-Token")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Security-Token", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-Algorithm")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Algorithm", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-SignedHeaders", valid_593400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593402: Call_UpdateVoiceConnector_593390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593402.validator(path, query, header, formData, body)
  let scheme = call_593402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593402.url(scheme.get, call_593402.host, call_593402.base,
                         call_593402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593402, url, valid)

proc call*(call_593403: Call_UpdateVoiceConnector_593390; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_593404 = newJObject()
  var body_593405 = newJObject()
  add(path_593404, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_593405 = body
  result = call_593403.call(path_593404, nil, nil, nil, body_593405)

var updateVoiceConnector* = Call_UpdateVoiceConnector_593390(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_593391, base: "/",
    url: url_UpdateVoiceConnector_593392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_593376 = ref object of OpenApiRestCall_592364
proc url_GetVoiceConnector_593378(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnector_593377(path: JsonNode; query: JsonNode;
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
  var valid_593379 = path.getOrDefault("voiceConnectorId")
  valid_593379 = validateParameter(valid_593379, JString, required = true,
                                 default = nil)
  if valid_593379 != nil:
    section.add "voiceConnectorId", valid_593379
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
  var valid_593380 = header.getOrDefault("X-Amz-Signature")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Signature", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Content-Sha256", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Date")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Date", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Credential")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Credential", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Security-Token")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Security-Token", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Algorithm")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Algorithm", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-SignedHeaders", valid_593386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593387: Call_GetVoiceConnector_593376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_593387.validator(path, query, header, formData, body)
  let scheme = call_593387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593387.url(scheme.get, call_593387.host, call_593387.base,
                         call_593387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593387, url, valid)

proc call*(call_593388: Call_GetVoiceConnector_593376; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593389 = newJObject()
  add(path_593389, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593388.call(path_593389, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_593376(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_593377, base: "/",
    url: url_GetVoiceConnector_593378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_593406 = ref object of OpenApiRestCall_592364
proc url_DeleteVoiceConnector_593408(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceConnector_593407(path: JsonNode; query: JsonNode;
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
  var valid_593409 = path.getOrDefault("voiceConnectorId")
  valid_593409 = validateParameter(valid_593409, JString, required = true,
                                 default = nil)
  if valid_593409 != nil:
    section.add "voiceConnectorId", valid_593409
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
  var valid_593410 = header.getOrDefault("X-Amz-Signature")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Signature", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Content-Sha256", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Date")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Date", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Credential")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Credential", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Security-Token")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Security-Token", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Algorithm")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Algorithm", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-SignedHeaders", valid_593416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593417: Call_DeleteVoiceConnector_593406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ## 
  let valid = call_593417.validator(path, query, header, formData, body)
  let scheme = call_593417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593417.url(scheme.get, call_593417.host, call_593417.base,
                         call_593417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593417, url, valid)

proc call*(call_593418: Call_DeleteVoiceConnector_593406; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593419 = newJObject()
  add(path_593419, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593418.call(path_593419, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_593406(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_593407, base: "/",
    url: url_DeleteVoiceConnector_593408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_593434 = ref object of OpenApiRestCall_592364
proc url_PutVoiceConnectorOrigination_593436(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorOrigination_593435(path: JsonNode; query: JsonNode;
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
  var valid_593437 = path.getOrDefault("voiceConnectorId")
  valid_593437 = validateParameter(valid_593437, JString, required = true,
                                 default = nil)
  if valid_593437 != nil:
    section.add "voiceConnectorId", valid_593437
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
  var valid_593438 = header.getOrDefault("X-Amz-Signature")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Signature", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Content-Sha256", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Date")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Date", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Credential")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Credential", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Security-Token")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Security-Token", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Algorithm")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Algorithm", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-SignedHeaders", valid_593444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593446: Call_PutVoiceConnectorOrigination_593434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593446.validator(path, query, header, formData, body)
  let scheme = call_593446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593446.url(scheme.get, call_593446.host, call_593446.base,
                         call_593446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593446, url, valid)

proc call*(call_593447: Call_PutVoiceConnectorOrigination_593434;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_593448 = newJObject()
  var body_593449 = newJObject()
  add(path_593448, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_593449 = body
  result = call_593447.call(path_593448, nil, nil, nil, body_593449)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_593434(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_593435, base: "/",
    url: url_PutVoiceConnectorOrigination_593436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_593420 = ref object of OpenApiRestCall_592364
proc url_GetVoiceConnectorOrigination_593422(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorOrigination_593421(path: JsonNode; query: JsonNode;
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
  var valid_593423 = path.getOrDefault("voiceConnectorId")
  valid_593423 = validateParameter(valid_593423, JString, required = true,
                                 default = nil)
  if valid_593423 != nil:
    section.add "voiceConnectorId", valid_593423
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
  var valid_593424 = header.getOrDefault("X-Amz-Signature")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Signature", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Content-Sha256", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Date")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Date", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Credential")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Credential", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Security-Token")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Security-Token", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Algorithm")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Algorithm", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-SignedHeaders", valid_593430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593431: Call_GetVoiceConnectorOrigination_593420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593431.validator(path, query, header, formData, body)
  let scheme = call_593431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593431.url(scheme.get, call_593431.host, call_593431.base,
                         call_593431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593431, url, valid)

proc call*(call_593432: Call_GetVoiceConnectorOrigination_593420;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593433 = newJObject()
  add(path_593433, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593432.call(path_593433, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_593420(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_593421, base: "/",
    url: url_GetVoiceConnectorOrigination_593422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_593450 = ref object of OpenApiRestCall_592364
proc url_DeleteVoiceConnectorOrigination_593452(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorOrigination_593451(path: JsonNode;
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
  var valid_593453 = path.getOrDefault("voiceConnectorId")
  valid_593453 = validateParameter(valid_593453, JString, required = true,
                                 default = nil)
  if valid_593453 != nil:
    section.add "voiceConnectorId", valid_593453
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
  var valid_593454 = header.getOrDefault("X-Amz-Signature")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Signature", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Content-Sha256", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Date")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Date", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Credential")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Credential", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Security-Token")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Security-Token", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Algorithm")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Algorithm", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-SignedHeaders", valid_593460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593461: Call_DeleteVoiceConnectorOrigination_593450;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593461.validator(path, query, header, formData, body)
  let scheme = call_593461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593461.url(scheme.get, call_593461.host, call_593461.base,
                         call_593461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593461, url, valid)

proc call*(call_593462: Call_DeleteVoiceConnectorOrigination_593450;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593463 = newJObject()
  add(path_593463, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593462.call(path_593463, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_593450(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_593451, base: "/",
    url: url_DeleteVoiceConnectorOrigination_593452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_593478 = ref object of OpenApiRestCall_592364
proc url_PutVoiceConnectorTermination_593480(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorTermination_593479(path: JsonNode; query: JsonNode;
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
  var valid_593481 = path.getOrDefault("voiceConnectorId")
  valid_593481 = validateParameter(valid_593481, JString, required = true,
                                 default = nil)
  if valid_593481 != nil:
    section.add "voiceConnectorId", valid_593481
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
  var valid_593482 = header.getOrDefault("X-Amz-Signature")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Signature", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Content-Sha256", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Date")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Date", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Credential")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Credential", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Security-Token")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Security-Token", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Algorithm")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Algorithm", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-SignedHeaders", valid_593488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593490: Call_PutVoiceConnectorTermination_593478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593490.validator(path, query, header, formData, body)
  let scheme = call_593490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593490.url(scheme.get, call_593490.host, call_593490.base,
                         call_593490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593490, url, valid)

proc call*(call_593491: Call_PutVoiceConnectorTermination_593478;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_593492 = newJObject()
  var body_593493 = newJObject()
  add(path_593492, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_593493 = body
  result = call_593491.call(path_593492, nil, nil, nil, body_593493)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_593478(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_593479, base: "/",
    url: url_PutVoiceConnectorTermination_593480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_593464 = ref object of OpenApiRestCall_592364
proc url_GetVoiceConnectorTermination_593466(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTermination_593465(path: JsonNode; query: JsonNode;
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
  var valid_593467 = path.getOrDefault("voiceConnectorId")
  valid_593467 = validateParameter(valid_593467, JString, required = true,
                                 default = nil)
  if valid_593467 != nil:
    section.add "voiceConnectorId", valid_593467
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
  var valid_593468 = header.getOrDefault("X-Amz-Signature")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Signature", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Content-Sha256", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Date")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Date", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Credential")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Credential", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Security-Token")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Security-Token", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Algorithm")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Algorithm", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-SignedHeaders", valid_593474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593475: Call_GetVoiceConnectorTermination_593464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593475.validator(path, query, header, formData, body)
  let scheme = call_593475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593475.url(scheme.get, call_593475.host, call_593475.base,
                         call_593475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593475, url, valid)

proc call*(call_593476: Call_GetVoiceConnectorTermination_593464;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593477 = newJObject()
  add(path_593477, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593476.call(path_593477, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_593464(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_593465, base: "/",
    url: url_GetVoiceConnectorTermination_593466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_593494 = ref object of OpenApiRestCall_592364
proc url_DeleteVoiceConnectorTermination_593496(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorTermination_593495(path: JsonNode;
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
  var valid_593497 = path.getOrDefault("voiceConnectorId")
  valid_593497 = validateParameter(valid_593497, JString, required = true,
                                 default = nil)
  if valid_593497 != nil:
    section.add "voiceConnectorId", valid_593497
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
  var valid_593498 = header.getOrDefault("X-Amz-Signature")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Signature", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Content-Sha256", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Date")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Date", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Credential")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Credential", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Security-Token")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Security-Token", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Algorithm")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Algorithm", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-SignedHeaders", valid_593504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593505: Call_DeleteVoiceConnectorTermination_593494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593505.validator(path, query, header, formData, body)
  let scheme = call_593505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593505.url(scheme.get, call_593505.host, call_593505.base,
                         call_593505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593505, url, valid)

proc call*(call_593506: Call_DeleteVoiceConnectorTermination_593494;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593507 = newJObject()
  add(path_593507, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593506.call(path_593507, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_593494(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_593495, base: "/",
    url: url_DeleteVoiceConnectorTermination_593496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_593508 = ref object of OpenApiRestCall_592364
proc url_DeleteVoiceConnectorTerminationCredentials_593510(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorTerminationCredentials_593509(path: JsonNode;
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
  var valid_593511 = path.getOrDefault("voiceConnectorId")
  valid_593511 = validateParameter(valid_593511, JString, required = true,
                                 default = nil)
  if valid_593511 != nil:
    section.add "voiceConnectorId", valid_593511
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593512 = query.getOrDefault("operation")
  valid_593512 = validateParameter(valid_593512, JString, required = true,
                                 default = newJString("delete"))
  if valid_593512 != nil:
    section.add "operation", valid_593512
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593513 = header.getOrDefault("X-Amz-Signature")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-Signature", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-Content-Sha256", valid_593514
  var valid_593515 = header.getOrDefault("X-Amz-Date")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Date", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Credential")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Credential", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Security-Token")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Security-Token", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Algorithm")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Algorithm", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-SignedHeaders", valid_593519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593521: Call_DeleteVoiceConnectorTerminationCredentials_593508;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_593521.validator(path, query, header, formData, body)
  let scheme = call_593521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593521.url(scheme.get, call_593521.host, call_593521.base,
                         call_593521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593521, url, valid)

proc call*(call_593522: Call_DeleteVoiceConnectorTerminationCredentials_593508;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_593523 = newJObject()
  var query_593524 = newJObject()
  var body_593525 = newJObject()
  add(query_593524, "operation", newJString(operation))
  add(path_593523, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_593525 = body
  result = call_593522.call(path_593523, query_593524, nil, nil, body_593525)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_593508(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_593509,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_593510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_593526 = ref object of OpenApiRestCall_592364
proc url_DisassociatePhoneNumberFromUser_593528(protocol: Scheme; host: string;
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

proc validate_DisassociatePhoneNumberFromUser_593527(path: JsonNode;
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
  var valid_593529 = path.getOrDefault("userId")
  valid_593529 = validateParameter(valid_593529, JString, required = true,
                                 default = nil)
  if valid_593529 != nil:
    section.add "userId", valid_593529
  var valid_593530 = path.getOrDefault("accountId")
  valid_593530 = validateParameter(valid_593530, JString, required = true,
                                 default = nil)
  if valid_593530 != nil:
    section.add "accountId", valid_593530
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593531 = query.getOrDefault("operation")
  valid_593531 = validateParameter(valid_593531, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_593531 != nil:
    section.add "operation", valid_593531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593532 = header.getOrDefault("X-Amz-Signature")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Signature", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Content-Sha256", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Date")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Date", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Credential")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Credential", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Security-Token")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Security-Token", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Algorithm")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Algorithm", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-SignedHeaders", valid_593538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593539: Call_DisassociatePhoneNumberFromUser_593526;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_593539.validator(path, query, header, formData, body)
  let scheme = call_593539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593539.url(scheme.get, call_593539.host, call_593539.base,
                         call_593539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593539, url, valid)

proc call*(call_593540: Call_DisassociatePhoneNumberFromUser_593526;
          userId: string; accountId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593541 = newJObject()
  var query_593542 = newJObject()
  add(query_593542, "operation", newJString(operation))
  add(path_593541, "userId", newJString(userId))
  add(path_593541, "accountId", newJString(accountId))
  result = call_593540.call(path_593541, query_593542, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_593526(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_593527, base: "/",
    url: url_DisassociatePhoneNumberFromUser_593528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_593543 = ref object of OpenApiRestCall_592364
proc url_DisassociatePhoneNumbersFromVoiceConnector_593545(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnector_593544(path: JsonNode;
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
  var valid_593546 = path.getOrDefault("voiceConnectorId")
  valid_593546 = validateParameter(valid_593546, JString, required = true,
                                 default = nil)
  if valid_593546 != nil:
    section.add "voiceConnectorId", valid_593546
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593547 = query.getOrDefault("operation")
  valid_593547 = validateParameter(valid_593547, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_593547 != nil:
    section.add "operation", valid_593547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593548 = header.getOrDefault("X-Amz-Signature")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Signature", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Content-Sha256", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Date")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Date", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Credential")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Credential", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-Security-Token")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Security-Token", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Algorithm")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Algorithm", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-SignedHeaders", valid_593554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593556: Call_DisassociatePhoneNumbersFromVoiceConnector_593543;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593556.validator(path, query, header, formData, body)
  let scheme = call_593556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593556.url(scheme.get, call_593556.host, call_593556.base,
                         call_593556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593556, url, valid)

proc call*(call_593557: Call_DisassociatePhoneNumbersFromVoiceConnector_593543;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_593558 = newJObject()
  var query_593559 = newJObject()
  var body_593560 = newJObject()
  add(query_593559, "operation", newJString(operation))
  add(path_593558, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_593560 = body
  result = call_593557.call(path_593558, query_593559, nil, nil, body_593560)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_593543(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_593544,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_593545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_593575 = ref object of OpenApiRestCall_592364
proc url_UpdateAccountSettings_593577(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccountSettings_593576(path: JsonNode; query: JsonNode;
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
  var valid_593578 = path.getOrDefault("accountId")
  valid_593578 = validateParameter(valid_593578, JString, required = true,
                                 default = nil)
  if valid_593578 != nil:
    section.add "accountId", valid_593578
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
  var valid_593579 = header.getOrDefault("X-Amz-Signature")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Signature", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Content-Sha256", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-Date")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Date", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Credential")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Credential", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Security-Token")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Security-Token", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Algorithm")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Algorithm", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-SignedHeaders", valid_593585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593587: Call_UpdateAccountSettings_593575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_593587.validator(path, query, header, formData, body)
  let scheme = call_593587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593587.url(scheme.get, call_593587.host, call_593587.base,
                         call_593587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593587, url, valid)

proc call*(call_593588: Call_UpdateAccountSettings_593575; body: JsonNode;
          accountId: string): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593589 = newJObject()
  var body_593590 = newJObject()
  if body != nil:
    body_593590 = body
  add(path_593589, "accountId", newJString(accountId))
  result = call_593588.call(path_593589, nil, nil, nil, body_593590)

var updateAccountSettings* = Call_UpdateAccountSettings_593575(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_593576, base: "/",
    url: url_UpdateAccountSettings_593577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_593561 = ref object of OpenApiRestCall_592364
proc url_GetAccountSettings_593563(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_593562(path: JsonNode; query: JsonNode;
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
  var valid_593564 = path.getOrDefault("accountId")
  valid_593564 = validateParameter(valid_593564, JString, required = true,
                                 default = nil)
  if valid_593564 != nil:
    section.add "accountId", valid_593564
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
  var valid_593565 = header.getOrDefault("X-Amz-Signature")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Signature", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Content-Sha256", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Date")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Date", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Credential")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Credential", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-Security-Token")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Security-Token", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-Algorithm")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-Algorithm", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-SignedHeaders", valid_593571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593572: Call_GetAccountSettings_593561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_593572.validator(path, query, header, formData, body)
  let scheme = call_593572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593572.url(scheme.get, call_593572.host, call_593572.base,
                         call_593572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593572, url, valid)

proc call*(call_593573: Call_GetAccountSettings_593561; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593574 = newJObject()
  add(path_593574, "accountId", newJString(accountId))
  result = call_593573.call(path_593574, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_593561(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_593562, base: "/",
    url: url_GetAccountSettings_593563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_593606 = ref object of OpenApiRestCall_592364
proc url_UpdateBot_593608(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateBot_593607(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593609 = path.getOrDefault("botId")
  valid_593609 = validateParameter(valid_593609, JString, required = true,
                                 default = nil)
  if valid_593609 != nil:
    section.add "botId", valid_593609
  var valid_593610 = path.getOrDefault("accountId")
  valid_593610 = validateParameter(valid_593610, JString, required = true,
                                 default = nil)
  if valid_593610 != nil:
    section.add "accountId", valid_593610
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
  var valid_593611 = header.getOrDefault("X-Amz-Signature")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-Signature", valid_593611
  var valid_593612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "X-Amz-Content-Sha256", valid_593612
  var valid_593613 = header.getOrDefault("X-Amz-Date")
  valid_593613 = validateParameter(valid_593613, JString, required = false,
                                 default = nil)
  if valid_593613 != nil:
    section.add "X-Amz-Date", valid_593613
  var valid_593614 = header.getOrDefault("X-Amz-Credential")
  valid_593614 = validateParameter(valid_593614, JString, required = false,
                                 default = nil)
  if valid_593614 != nil:
    section.add "X-Amz-Credential", valid_593614
  var valid_593615 = header.getOrDefault("X-Amz-Security-Token")
  valid_593615 = validateParameter(valid_593615, JString, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "X-Amz-Security-Token", valid_593615
  var valid_593616 = header.getOrDefault("X-Amz-Algorithm")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "X-Amz-Algorithm", valid_593616
  var valid_593617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-SignedHeaders", valid_593617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593619: Call_UpdateBot_593606; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_593619.validator(path, query, header, formData, body)
  let scheme = call_593619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593619.url(scheme.get, call_593619.host, call_593619.base,
                         call_593619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593619, url, valid)

proc call*(call_593620: Call_UpdateBot_593606; botId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593621 = newJObject()
  var body_593622 = newJObject()
  add(path_593621, "botId", newJString(botId))
  if body != nil:
    body_593622 = body
  add(path_593621, "accountId", newJString(accountId))
  result = call_593620.call(path_593621, nil, nil, nil, body_593622)

var updateBot* = Call_UpdateBot_593606(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_593607,
                                    base: "/", url: url_UpdateBot_593608,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_593591 = ref object of OpenApiRestCall_592364
proc url_GetBot_593593(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_593592(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593594 = path.getOrDefault("botId")
  valid_593594 = validateParameter(valid_593594, JString, required = true,
                                 default = nil)
  if valid_593594 != nil:
    section.add "botId", valid_593594
  var valid_593595 = path.getOrDefault("accountId")
  valid_593595 = validateParameter(valid_593595, JString, required = true,
                                 default = nil)
  if valid_593595 != nil:
    section.add "accountId", valid_593595
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
  var valid_593596 = header.getOrDefault("X-Amz-Signature")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Signature", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-Content-Sha256", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Date")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Date", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Credential")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Credential", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Security-Token")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Security-Token", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Algorithm")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Algorithm", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-SignedHeaders", valid_593602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593603: Call_GetBot_593591; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_593603.validator(path, query, header, formData, body)
  let scheme = call_593603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593603.url(scheme.get, call_593603.host, call_593603.base,
                         call_593603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593603, url, valid)

proc call*(call_593604: Call_GetBot_593591; botId: string; accountId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593605 = newJObject()
  add(path_593605, "botId", newJString(botId))
  add(path_593605, "accountId", newJString(accountId))
  result = call_593604.call(path_593605, nil, nil, nil, nil)

var getBot* = Call_GetBot_593591(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_593592, base: "/",
                              url: url_GetBot_593593,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_593635 = ref object of OpenApiRestCall_592364
proc url_UpdateGlobalSettings_593637(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGlobalSettings_593636(path: JsonNode; query: JsonNode;
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
  var valid_593638 = header.getOrDefault("X-Amz-Signature")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Signature", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Content-Sha256", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Date")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Date", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Credential")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Credential", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Security-Token")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Security-Token", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Algorithm")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Algorithm", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-SignedHeaders", valid_593644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593646: Call_UpdateGlobalSettings_593635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_593646.validator(path, query, header, formData, body)
  let scheme = call_593646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593646.url(scheme.get, call_593646.host, call_593646.base,
                         call_593646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593646, url, valid)

proc call*(call_593647: Call_UpdateGlobalSettings_593635; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_593648 = newJObject()
  if body != nil:
    body_593648 = body
  result = call_593647.call(nil, nil, nil, nil, body_593648)

var updateGlobalSettings* = Call_UpdateGlobalSettings_593635(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_593636, base: "/",
    url: url_UpdateGlobalSettings_593637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_593623 = ref object of OpenApiRestCall_592364
proc url_GetGlobalSettings_593625(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGlobalSettings_593624(path: JsonNode; query: JsonNode;
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
  var valid_593626 = header.getOrDefault("X-Amz-Signature")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Signature", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Content-Sha256", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Date")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Date", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-Credential")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-Credential", valid_593629
  var valid_593630 = header.getOrDefault("X-Amz-Security-Token")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-Security-Token", valid_593630
  var valid_593631 = header.getOrDefault("X-Amz-Algorithm")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "X-Amz-Algorithm", valid_593631
  var valid_593632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-SignedHeaders", valid_593632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593633: Call_GetGlobalSettings_593623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_593633.validator(path, query, header, formData, body)
  let scheme = call_593633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593633.url(scheme.get, call_593633.host, call_593633.base,
                         call_593633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593633, url, valid)

proc call*(call_593634: Call_GetGlobalSettings_593623): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_593634.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_593623(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_593624, base: "/",
    url: url_GetGlobalSettings_593625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_593649 = ref object of OpenApiRestCall_592364
proc url_GetPhoneNumberOrder_593651(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberOrder_593650(path: JsonNode; query: JsonNode;
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
  var valid_593652 = path.getOrDefault("phoneNumberOrderId")
  valid_593652 = validateParameter(valid_593652, JString, required = true,
                                 default = nil)
  if valid_593652 != nil:
    section.add "phoneNumberOrderId", valid_593652
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
  var valid_593653 = header.getOrDefault("X-Amz-Signature")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Signature", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Content-Sha256", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-Date")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-Date", valid_593655
  var valid_593656 = header.getOrDefault("X-Amz-Credential")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-Credential", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-Security-Token")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Security-Token", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Algorithm")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Algorithm", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-SignedHeaders", valid_593659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593660: Call_GetPhoneNumberOrder_593649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_593660.validator(path, query, header, formData, body)
  let scheme = call_593660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593660.url(scheme.get, call_593660.host, call_593660.base,
                         call_593660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593660, url, valid)

proc call*(call_593661: Call_GetPhoneNumberOrder_593649; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_593662 = newJObject()
  add(path_593662, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_593661.call(path_593662, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_593649(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_593650, base: "/",
    url: url_GetPhoneNumberOrder_593651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_593678 = ref object of OpenApiRestCall_592364
proc url_UpdateUser_593680(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_593679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593681 = path.getOrDefault("userId")
  valid_593681 = validateParameter(valid_593681, JString, required = true,
                                 default = nil)
  if valid_593681 != nil:
    section.add "userId", valid_593681
  var valid_593682 = path.getOrDefault("accountId")
  valid_593682 = validateParameter(valid_593682, JString, required = true,
                                 default = nil)
  if valid_593682 != nil:
    section.add "accountId", valid_593682
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
  var valid_593683 = header.getOrDefault("X-Amz-Signature")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-Signature", valid_593683
  var valid_593684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "X-Amz-Content-Sha256", valid_593684
  var valid_593685 = header.getOrDefault("X-Amz-Date")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Date", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-Credential")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-Credential", valid_593686
  var valid_593687 = header.getOrDefault("X-Amz-Security-Token")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "X-Amz-Security-Token", valid_593687
  var valid_593688 = header.getOrDefault("X-Amz-Algorithm")
  valid_593688 = validateParameter(valid_593688, JString, required = false,
                                 default = nil)
  if valid_593688 != nil:
    section.add "X-Amz-Algorithm", valid_593688
  var valid_593689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593689 = validateParameter(valid_593689, JString, required = false,
                                 default = nil)
  if valid_593689 != nil:
    section.add "X-Amz-SignedHeaders", valid_593689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593691: Call_UpdateUser_593678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_593691.validator(path, query, header, formData, body)
  let scheme = call_593691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593691.url(scheme.get, call_593691.host, call_593691.base,
                         call_593691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593691, url, valid)

proc call*(call_593692: Call_UpdateUser_593678; userId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593693 = newJObject()
  var body_593694 = newJObject()
  add(path_593693, "userId", newJString(userId))
  if body != nil:
    body_593694 = body
  add(path_593693, "accountId", newJString(accountId))
  result = call_593692.call(path_593693, nil, nil, nil, body_593694)

var updateUser* = Call_UpdateUser_593678(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_593679,
                                      base: "/", url: url_UpdateUser_593680,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_593663 = ref object of OpenApiRestCall_592364
proc url_GetUser_593665(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_593664(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593666 = path.getOrDefault("userId")
  valid_593666 = validateParameter(valid_593666, JString, required = true,
                                 default = nil)
  if valid_593666 != nil:
    section.add "userId", valid_593666
  var valid_593667 = path.getOrDefault("accountId")
  valid_593667 = validateParameter(valid_593667, JString, required = true,
                                 default = nil)
  if valid_593667 != nil:
    section.add "accountId", valid_593667
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
  var valid_593668 = header.getOrDefault("X-Amz-Signature")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Signature", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Content-Sha256", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-Date")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-Date", valid_593670
  var valid_593671 = header.getOrDefault("X-Amz-Credential")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "X-Amz-Credential", valid_593671
  var valid_593672 = header.getOrDefault("X-Amz-Security-Token")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "X-Amz-Security-Token", valid_593672
  var valid_593673 = header.getOrDefault("X-Amz-Algorithm")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "X-Amz-Algorithm", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-SignedHeaders", valid_593674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593675: Call_GetUser_593663; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_593675.validator(path, query, header, formData, body)
  let scheme = call_593675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593675.url(scheme.get, call_593675.host, call_593675.base,
                         call_593675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593675, url, valid)

proc call*(call_593676: Call_GetUser_593663; userId: string; accountId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593677 = newJObject()
  add(path_593677, "userId", newJString(userId))
  add(path_593677, "accountId", newJString(accountId))
  result = call_593676.call(path_593677, nil, nil, nil, nil)

var getUser* = Call_GetUser_593663(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_593664, base: "/",
                                url: url_GetUser_593665,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_593710 = ref object of OpenApiRestCall_592364
proc url_UpdateUserSettings_593712(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserSettings_593711(path: JsonNode; query: JsonNode;
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
  var valid_593713 = path.getOrDefault("userId")
  valid_593713 = validateParameter(valid_593713, JString, required = true,
                                 default = nil)
  if valid_593713 != nil:
    section.add "userId", valid_593713
  var valid_593714 = path.getOrDefault("accountId")
  valid_593714 = validateParameter(valid_593714, JString, required = true,
                                 default = nil)
  if valid_593714 != nil:
    section.add "accountId", valid_593714
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
  var valid_593715 = header.getOrDefault("X-Amz-Signature")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "X-Amz-Signature", valid_593715
  var valid_593716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "X-Amz-Content-Sha256", valid_593716
  var valid_593717 = header.getOrDefault("X-Amz-Date")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "X-Amz-Date", valid_593717
  var valid_593718 = header.getOrDefault("X-Amz-Credential")
  valid_593718 = validateParameter(valid_593718, JString, required = false,
                                 default = nil)
  if valid_593718 != nil:
    section.add "X-Amz-Credential", valid_593718
  var valid_593719 = header.getOrDefault("X-Amz-Security-Token")
  valid_593719 = validateParameter(valid_593719, JString, required = false,
                                 default = nil)
  if valid_593719 != nil:
    section.add "X-Amz-Security-Token", valid_593719
  var valid_593720 = header.getOrDefault("X-Amz-Algorithm")
  valid_593720 = validateParameter(valid_593720, JString, required = false,
                                 default = nil)
  if valid_593720 != nil:
    section.add "X-Amz-Algorithm", valid_593720
  var valid_593721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "X-Amz-SignedHeaders", valid_593721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593723: Call_UpdateUserSettings_593710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_593723.validator(path, query, header, formData, body)
  let scheme = call_593723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593723.url(scheme.get, call_593723.host, call_593723.base,
                         call_593723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593723, url, valid)

proc call*(call_593724: Call_UpdateUserSettings_593710; userId: string;
          body: JsonNode; accountId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593725 = newJObject()
  var body_593726 = newJObject()
  add(path_593725, "userId", newJString(userId))
  if body != nil:
    body_593726 = body
  add(path_593725, "accountId", newJString(accountId))
  result = call_593724.call(path_593725, nil, nil, nil, body_593726)

var updateUserSettings* = Call_UpdateUserSettings_593710(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_593711, base: "/",
    url: url_UpdateUserSettings_593712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_593695 = ref object of OpenApiRestCall_592364
proc url_GetUserSettings_593697(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserSettings_593696(path: JsonNode; query: JsonNode;
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
  var valid_593698 = path.getOrDefault("userId")
  valid_593698 = validateParameter(valid_593698, JString, required = true,
                                 default = nil)
  if valid_593698 != nil:
    section.add "userId", valid_593698
  var valid_593699 = path.getOrDefault("accountId")
  valid_593699 = validateParameter(valid_593699, JString, required = true,
                                 default = nil)
  if valid_593699 != nil:
    section.add "accountId", valid_593699
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
  var valid_593700 = header.getOrDefault("X-Amz-Signature")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Signature", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-Content-Sha256", valid_593701
  var valid_593702 = header.getOrDefault("X-Amz-Date")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "X-Amz-Date", valid_593702
  var valid_593703 = header.getOrDefault("X-Amz-Credential")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "X-Amz-Credential", valid_593703
  var valid_593704 = header.getOrDefault("X-Amz-Security-Token")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "X-Amz-Security-Token", valid_593704
  var valid_593705 = header.getOrDefault("X-Amz-Algorithm")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "X-Amz-Algorithm", valid_593705
  var valid_593706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-SignedHeaders", valid_593706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593707: Call_GetUserSettings_593695; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_593707.validator(path, query, header, formData, body)
  let scheme = call_593707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593707.url(scheme.get, call_593707.host, call_593707.base,
                         call_593707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593707, url, valid)

proc call*(call_593708: Call_GetUserSettings_593695; userId: string;
          accountId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593709 = newJObject()
  add(path_593709, "userId", newJString(userId))
  add(path_593709, "accountId", newJString(accountId))
  result = call_593708.call(path_593709, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_593695(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_593696, base: "/", url: url_GetUserSettings_593697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_593727 = ref object of OpenApiRestCall_592364
proc url_GetVoiceConnectorTerminationHealth_593729(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTerminationHealth_593728(path: JsonNode;
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
  var valid_593730 = path.getOrDefault("voiceConnectorId")
  valid_593730 = validateParameter(valid_593730, JString, required = true,
                                 default = nil)
  if valid_593730 != nil:
    section.add "voiceConnectorId", valid_593730
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
  var valid_593731 = header.getOrDefault("X-Amz-Signature")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Signature", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-Content-Sha256", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-Date")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Date", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-Credential")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-Credential", valid_593734
  var valid_593735 = header.getOrDefault("X-Amz-Security-Token")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Security-Token", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-Algorithm")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-Algorithm", valid_593736
  var valid_593737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593737 = validateParameter(valid_593737, JString, required = false,
                                 default = nil)
  if valid_593737 != nil:
    section.add "X-Amz-SignedHeaders", valid_593737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593738: Call_GetVoiceConnectorTerminationHealth_593727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593738.validator(path, query, header, formData, body)
  let scheme = call_593738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593738.url(scheme.get, call_593738.host, call_593738.base,
                         call_593738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593738, url, valid)

proc call*(call_593739: Call_GetVoiceConnectorTerminationHealth_593727;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593740 = newJObject()
  add(path_593740, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593739.call(path_593740, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_593727(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_593728, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_593729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_593741 = ref object of OpenApiRestCall_592364
proc url_InviteUsers_593743(protocol: Scheme; host: string; base: string;
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

proc validate_InviteUsers_593742(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593744 = path.getOrDefault("accountId")
  valid_593744 = validateParameter(valid_593744, JString, required = true,
                                 default = nil)
  if valid_593744 != nil:
    section.add "accountId", valid_593744
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593745 = query.getOrDefault("operation")
  valid_593745 = validateParameter(valid_593745, JString, required = true,
                                 default = newJString("add"))
  if valid_593745 != nil:
    section.add "operation", valid_593745
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593746 = header.getOrDefault("X-Amz-Signature")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Signature", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-Content-Sha256", valid_593747
  var valid_593748 = header.getOrDefault("X-Amz-Date")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Date", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-Credential")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-Credential", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-Security-Token")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-Security-Token", valid_593750
  var valid_593751 = header.getOrDefault("X-Amz-Algorithm")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "X-Amz-Algorithm", valid_593751
  var valid_593752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593752 = validateParameter(valid_593752, JString, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "X-Amz-SignedHeaders", valid_593752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593754: Call_InviteUsers_593741; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_593754.validator(path, query, header, formData, body)
  let scheme = call_593754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593754.url(scheme.get, call_593754.host, call_593754.base,
                         call_593754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593754, url, valid)

proc call*(call_593755: Call_InviteUsers_593741; body: JsonNode; accountId: string;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593756 = newJObject()
  var query_593757 = newJObject()
  var body_593758 = newJObject()
  add(query_593757, "operation", newJString(operation))
  if body != nil:
    body_593758 = body
  add(path_593756, "accountId", newJString(accountId))
  result = call_593755.call(path_593756, query_593757, nil, nil, body_593758)

var inviteUsers* = Call_InviteUsers_593741(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_593742,
                                        base: "/", url: url_InviteUsers_593743,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_593759 = ref object of OpenApiRestCall_592364
proc url_ListPhoneNumbers_593761(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPhoneNumbers_593760(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
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
  var valid_593762 = query.getOrDefault("MaxResults")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "MaxResults", valid_593762
  var valid_593763 = query.getOrDefault("NextToken")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "NextToken", valid_593763
  var valid_593764 = query.getOrDefault("product-type")
  valid_593764 = validateParameter(valid_593764, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_593764 != nil:
    section.add "product-type", valid_593764
  var valid_593765 = query.getOrDefault("filter-name")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_593765 != nil:
    section.add "filter-name", valid_593765
  var valid_593766 = query.getOrDefault("max-results")
  valid_593766 = validateParameter(valid_593766, JInt, required = false, default = nil)
  if valid_593766 != nil:
    section.add "max-results", valid_593766
  var valid_593767 = query.getOrDefault("status")
  valid_593767 = validateParameter(valid_593767, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_593767 != nil:
    section.add "status", valid_593767
  var valid_593768 = query.getOrDefault("filter-value")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "filter-value", valid_593768
  var valid_593769 = query.getOrDefault("next-token")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "next-token", valid_593769
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593770 = header.getOrDefault("X-Amz-Signature")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Signature", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Content-Sha256", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Date")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Date", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Credential")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Credential", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Security-Token")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Security-Token", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Algorithm")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Algorithm", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-SignedHeaders", valid_593776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593777: Call_ListPhoneNumbers_593759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
  ## 
  let valid = call_593777.validator(path, query, header, formData, body)
  let scheme = call_593777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593777.url(scheme.get, call_593777.host, call_593777.base,
                         call_593777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593777, url, valid)

proc call*(call_593778: Call_ListPhoneNumbers_593759; MaxResults: string = "";
          NextToken: string = ""; productType: string = "BusinessCalling";
          filterName: string = "AccountId"; maxResults: int = 0;
          status: string = "AcquireInProgress"; filterValue: string = "";
          nextToken: string = ""): Recallable =
  ## listPhoneNumbers
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
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
  var query_593779 = newJObject()
  add(query_593779, "MaxResults", newJString(MaxResults))
  add(query_593779, "NextToken", newJString(NextToken))
  add(query_593779, "product-type", newJString(productType))
  add(query_593779, "filter-name", newJString(filterName))
  add(query_593779, "max-results", newJInt(maxResults))
  add(query_593779, "status", newJString(status))
  add(query_593779, "filter-value", newJString(filterValue))
  add(query_593779, "next-token", newJString(nextToken))
  result = call_593778.call(nil, query_593779, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_593759(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_593760, base: "/",
    url: url_ListPhoneNumbers_593761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_593780 = ref object of OpenApiRestCall_592364
proc url_ListVoiceConnectorTerminationCredentials_593782(protocol: Scheme;
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

proc validate_ListVoiceConnectorTerminationCredentials_593781(path: JsonNode;
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
  var valid_593783 = path.getOrDefault("voiceConnectorId")
  valid_593783 = validateParameter(valid_593783, JString, required = true,
                                 default = nil)
  if valid_593783 != nil:
    section.add "voiceConnectorId", valid_593783
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
  var valid_593784 = header.getOrDefault("X-Amz-Signature")
  valid_593784 = validateParameter(valid_593784, JString, required = false,
                                 default = nil)
  if valid_593784 != nil:
    section.add "X-Amz-Signature", valid_593784
  var valid_593785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "X-Amz-Content-Sha256", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-Date")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-Date", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-Credential")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-Credential", valid_593787
  var valid_593788 = header.getOrDefault("X-Amz-Security-Token")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "X-Amz-Security-Token", valid_593788
  var valid_593789 = header.getOrDefault("X-Amz-Algorithm")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "X-Amz-Algorithm", valid_593789
  var valid_593790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "X-Amz-SignedHeaders", valid_593790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593791: Call_ListVoiceConnectorTerminationCredentials_593780;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593791.validator(path, query, header, formData, body)
  let scheme = call_593791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593791.url(scheme.get, call_593791.host, call_593791.base,
                         call_593791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593791, url, valid)

proc call*(call_593792: Call_ListVoiceConnectorTerminationCredentials_593780;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_593793 = newJObject()
  add(path_593793, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_593792.call(path_593793, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_593780(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_593781,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_593782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_593794 = ref object of OpenApiRestCall_592364
proc url_LogoutUser_593796(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_LogoutUser_593795(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593797 = path.getOrDefault("userId")
  valid_593797 = validateParameter(valid_593797, JString, required = true,
                                 default = nil)
  if valid_593797 != nil:
    section.add "userId", valid_593797
  var valid_593798 = path.getOrDefault("accountId")
  valid_593798 = validateParameter(valid_593798, JString, required = true,
                                 default = nil)
  if valid_593798 != nil:
    section.add "accountId", valid_593798
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593799 = query.getOrDefault("operation")
  valid_593799 = validateParameter(valid_593799, JString, required = true,
                                 default = newJString("logout"))
  if valid_593799 != nil:
    section.add "operation", valid_593799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593800 = header.getOrDefault("X-Amz-Signature")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Signature", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-Content-Sha256", valid_593801
  var valid_593802 = header.getOrDefault("X-Amz-Date")
  valid_593802 = validateParameter(valid_593802, JString, required = false,
                                 default = nil)
  if valid_593802 != nil:
    section.add "X-Amz-Date", valid_593802
  var valid_593803 = header.getOrDefault("X-Amz-Credential")
  valid_593803 = validateParameter(valid_593803, JString, required = false,
                                 default = nil)
  if valid_593803 != nil:
    section.add "X-Amz-Credential", valid_593803
  var valid_593804 = header.getOrDefault("X-Amz-Security-Token")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-Security-Token", valid_593804
  var valid_593805 = header.getOrDefault("X-Amz-Algorithm")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Algorithm", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-SignedHeaders", valid_593806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593807: Call_LogoutUser_593794; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_593807.validator(path, query, header, formData, body)
  let scheme = call_593807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593807.url(scheme.get, call_593807.host, call_593807.base,
                         call_593807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593807, url, valid)

proc call*(call_593808: Call_LogoutUser_593794; userId: string; accountId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593809 = newJObject()
  var query_593810 = newJObject()
  add(query_593810, "operation", newJString(operation))
  add(path_593809, "userId", newJString(userId))
  add(path_593809, "accountId", newJString(accountId))
  result = call_593808.call(path_593809, query_593810, nil, nil, nil)

var logoutUser* = Call_LogoutUser_593794(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_593795,
                                      base: "/", url: url_LogoutUser_593796,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_593811 = ref object of OpenApiRestCall_592364
proc url_PutVoiceConnectorTerminationCredentials_593813(protocol: Scheme;
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

proc validate_PutVoiceConnectorTerminationCredentials_593812(path: JsonNode;
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
  var valid_593814 = path.getOrDefault("voiceConnectorId")
  valid_593814 = validateParameter(valid_593814, JString, required = true,
                                 default = nil)
  if valid_593814 != nil:
    section.add "voiceConnectorId", valid_593814
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593815 = query.getOrDefault("operation")
  valid_593815 = validateParameter(valid_593815, JString, required = true,
                                 default = newJString("put"))
  if valid_593815 != nil:
    section.add "operation", valid_593815
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593816 = header.getOrDefault("X-Amz-Signature")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-Signature", valid_593816
  var valid_593817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "X-Amz-Content-Sha256", valid_593817
  var valid_593818 = header.getOrDefault("X-Amz-Date")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "X-Amz-Date", valid_593818
  var valid_593819 = header.getOrDefault("X-Amz-Credential")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "X-Amz-Credential", valid_593819
  var valid_593820 = header.getOrDefault("X-Amz-Security-Token")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Security-Token", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Algorithm")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Algorithm", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-SignedHeaders", valid_593822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593824: Call_PutVoiceConnectorTerminationCredentials_593811;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_593824.validator(path, query, header, formData, body)
  let scheme = call_593824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593824.url(scheme.get, call_593824.host, call_593824.base,
                         call_593824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593824, url, valid)

proc call*(call_593825: Call_PutVoiceConnectorTerminationCredentials_593811;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_593826 = newJObject()
  var query_593827 = newJObject()
  var body_593828 = newJObject()
  add(query_593827, "operation", newJString(operation))
  add(path_593826, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_593828 = body
  result = call_593825.call(path_593826, query_593827, nil, nil, body_593828)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_593811(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_593812, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_593813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_593829 = ref object of OpenApiRestCall_592364
proc url_RegenerateSecurityToken_593831(protocol: Scheme; host: string; base: string;
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

proc validate_RegenerateSecurityToken_593830(path: JsonNode; query: JsonNode;
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
  var valid_593832 = path.getOrDefault("botId")
  valid_593832 = validateParameter(valid_593832, JString, required = true,
                                 default = nil)
  if valid_593832 != nil:
    section.add "botId", valid_593832
  var valid_593833 = path.getOrDefault("accountId")
  valid_593833 = validateParameter(valid_593833, JString, required = true,
                                 default = nil)
  if valid_593833 != nil:
    section.add "accountId", valid_593833
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593834 = query.getOrDefault("operation")
  valid_593834 = validateParameter(valid_593834, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_593834 != nil:
    section.add "operation", valid_593834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593835 = header.getOrDefault("X-Amz-Signature")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Signature", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Content-Sha256", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Date")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Date", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Credential")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Credential", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Security-Token")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Security-Token", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Algorithm")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Algorithm", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-SignedHeaders", valid_593841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593842: Call_RegenerateSecurityToken_593829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_593842.validator(path, query, header, formData, body)
  let scheme = call_593842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593842.url(scheme.get, call_593842.host, call_593842.base,
                         call_593842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593842, url, valid)

proc call*(call_593843: Call_RegenerateSecurityToken_593829; botId: string;
          accountId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593844 = newJObject()
  var query_593845 = newJObject()
  add(path_593844, "botId", newJString(botId))
  add(query_593845, "operation", newJString(operation))
  add(path_593844, "accountId", newJString(accountId))
  result = call_593843.call(path_593844, query_593845, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_593829(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_593830, base: "/",
    url: url_RegenerateSecurityToken_593831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_593846 = ref object of OpenApiRestCall_592364
proc url_ResetPersonalPIN_593848(protocol: Scheme; host: string; base: string;
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

proc validate_ResetPersonalPIN_593847(path: JsonNode; query: JsonNode;
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
  var valid_593849 = path.getOrDefault("userId")
  valid_593849 = validateParameter(valid_593849, JString, required = true,
                                 default = nil)
  if valid_593849 != nil:
    section.add "userId", valid_593849
  var valid_593850 = path.getOrDefault("accountId")
  valid_593850 = validateParameter(valid_593850, JString, required = true,
                                 default = nil)
  if valid_593850 != nil:
    section.add "accountId", valid_593850
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593851 = query.getOrDefault("operation")
  valid_593851 = validateParameter(valid_593851, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_593851 != nil:
    section.add "operation", valid_593851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593852 = header.getOrDefault("X-Amz-Signature")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Signature", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Content-Sha256", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-Date")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Date", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Credential")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Credential", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Security-Token")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Security-Token", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Algorithm")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Algorithm", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-SignedHeaders", valid_593858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593859: Call_ResetPersonalPIN_593846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_593859.validator(path, query, header, formData, body)
  let scheme = call_593859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593859.url(scheme.get, call_593859.host, call_593859.base,
                         call_593859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593859, url, valid)

proc call*(call_593860: Call_ResetPersonalPIN_593846; userId: string;
          accountId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_593861 = newJObject()
  var query_593862 = newJObject()
  add(query_593862, "operation", newJString(operation))
  add(path_593861, "userId", newJString(userId))
  add(path_593861, "accountId", newJString(accountId))
  result = call_593860.call(path_593861, query_593862, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_593846(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_593847, base: "/",
    url: url_ResetPersonalPIN_593848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_593863 = ref object of OpenApiRestCall_592364
proc url_RestorePhoneNumber_593865(protocol: Scheme; host: string; base: string;
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

proc validate_RestorePhoneNumber_593864(path: JsonNode; query: JsonNode;
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
  var valid_593866 = path.getOrDefault("phoneNumberId")
  valid_593866 = validateParameter(valid_593866, JString, required = true,
                                 default = nil)
  if valid_593866 != nil:
    section.add "phoneNumberId", valid_593866
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_593867 = query.getOrDefault("operation")
  valid_593867 = validateParameter(valid_593867, JString, required = true,
                                 default = newJString("restore"))
  if valid_593867 != nil:
    section.add "operation", valid_593867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593868 = header.getOrDefault("X-Amz-Signature")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "X-Amz-Signature", valid_593868
  var valid_593869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-Content-Sha256", valid_593869
  var valid_593870 = header.getOrDefault("X-Amz-Date")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Date", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Credential")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Credential", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Security-Token")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Security-Token", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Algorithm")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Algorithm", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-SignedHeaders", valid_593874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593875: Call_RestorePhoneNumber_593863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_593875.validator(path, query, header, formData, body)
  let scheme = call_593875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593875.url(scheme.get, call_593875.host, call_593875.base,
                         call_593875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593875, url, valid)

proc call*(call_593876: Call_RestorePhoneNumber_593863; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_593877 = newJObject()
  var query_593878 = newJObject()
  add(path_593877, "phoneNumberId", newJString(phoneNumberId))
  add(query_593878, "operation", newJString(operation))
  result = call_593876.call(path_593877, query_593878, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_593863(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_593864, base: "/",
    url: url_RestorePhoneNumber_593865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_593879 = ref object of OpenApiRestCall_592364
proc url_SearchAvailablePhoneNumbers_593881(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchAvailablePhoneNumbers_593880(path: JsonNode; query: JsonNode;
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
  var valid_593882 = query.getOrDefault("state")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "state", valid_593882
  var valid_593883 = query.getOrDefault("area-code")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "area-code", valid_593883
  var valid_593884 = query.getOrDefault("toll-free-prefix")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "toll-free-prefix", valid_593884
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_593885 = query.getOrDefault("type")
  valid_593885 = validateParameter(valid_593885, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_593885 != nil:
    section.add "type", valid_593885
  var valid_593886 = query.getOrDefault("city")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "city", valid_593886
  var valid_593887 = query.getOrDefault("country")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "country", valid_593887
  var valid_593888 = query.getOrDefault("max-results")
  valid_593888 = validateParameter(valid_593888, JInt, required = false, default = nil)
  if valid_593888 != nil:
    section.add "max-results", valid_593888
  var valid_593889 = query.getOrDefault("next-token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "next-token", valid_593889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593890 = header.getOrDefault("X-Amz-Signature")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Signature", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Content-Sha256", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Date")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Date", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Credential")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Credential", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Security-Token")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Security-Token", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Algorithm")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Algorithm", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-SignedHeaders", valid_593896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593897: Call_SearchAvailablePhoneNumbers_593879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_593897.validator(path, query, header, formData, body)
  let scheme = call_593897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593897.url(scheme.get, call_593897.host, call_593897.base,
                         call_593897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593897, url, valid)

proc call*(call_593898: Call_SearchAvailablePhoneNumbers_593879;
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
  var query_593899 = newJObject()
  add(query_593899, "state", newJString(state))
  add(query_593899, "area-code", newJString(areaCode))
  add(query_593899, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_593899, "type", newJString(`type`))
  add(query_593899, "city", newJString(city))
  add(query_593899, "country", newJString(country))
  add(query_593899, "max-results", newJInt(maxResults))
  add(query_593899, "next-token", newJString(nextToken))
  result = call_593898.call(nil, query_593899, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_593879(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_593880, base: "/",
    url: url_SearchAvailablePhoneNumbers_593881,
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
