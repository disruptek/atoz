
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
  Call_AssociatePhoneNumberWithUser_590703 = ref object of OpenApiRestCall_590364
proc url_AssociatePhoneNumberWithUser_590705(protocol: Scheme; host: string;
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

proc validate_AssociatePhoneNumberWithUser_590704(path: JsonNode; query: JsonNode;
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
  var valid_590831 = path.getOrDefault("userId")
  valid_590831 = validateParameter(valid_590831, JString, required = true,
                                 default = nil)
  if valid_590831 != nil:
    section.add "userId", valid_590831
  var valid_590832 = path.getOrDefault("accountId")
  valid_590832 = validateParameter(valid_590832, JString, required = true,
                                 default = nil)
  if valid_590832 != nil:
    section.add "accountId", valid_590832
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_590846 = query.getOrDefault("operation")
  valid_590846 = validateParameter(valid_590846, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_590846 != nil:
    section.add "operation", valid_590846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590847 = header.getOrDefault("X-Amz-Signature")
  valid_590847 = validateParameter(valid_590847, JString, required = false,
                                 default = nil)
  if valid_590847 != nil:
    section.add "X-Amz-Signature", valid_590847
  var valid_590848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590848 = validateParameter(valid_590848, JString, required = false,
                                 default = nil)
  if valid_590848 != nil:
    section.add "X-Amz-Content-Sha256", valid_590848
  var valid_590849 = header.getOrDefault("X-Amz-Date")
  valid_590849 = validateParameter(valid_590849, JString, required = false,
                                 default = nil)
  if valid_590849 != nil:
    section.add "X-Amz-Date", valid_590849
  var valid_590850 = header.getOrDefault("X-Amz-Credential")
  valid_590850 = validateParameter(valid_590850, JString, required = false,
                                 default = nil)
  if valid_590850 != nil:
    section.add "X-Amz-Credential", valid_590850
  var valid_590851 = header.getOrDefault("X-Amz-Security-Token")
  valid_590851 = validateParameter(valid_590851, JString, required = false,
                                 default = nil)
  if valid_590851 != nil:
    section.add "X-Amz-Security-Token", valid_590851
  var valid_590852 = header.getOrDefault("X-Amz-Algorithm")
  valid_590852 = validateParameter(valid_590852, JString, required = false,
                                 default = nil)
  if valid_590852 != nil:
    section.add "X-Amz-Algorithm", valid_590852
  var valid_590853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590853 = validateParameter(valid_590853, JString, required = false,
                                 default = nil)
  if valid_590853 != nil:
    section.add "X-Amz-SignedHeaders", valid_590853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590877: Call_AssociatePhoneNumberWithUser_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_590877.validator(path, query, header, formData, body)
  let scheme = call_590877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590877.url(scheme.get, call_590877.host, call_590877.base,
                         call_590877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590877, url, valid)

proc call*(call_590948: Call_AssociatePhoneNumberWithUser_590703; userId: string;
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
  var path_590949 = newJObject()
  var query_590951 = newJObject()
  var body_590952 = newJObject()
  add(query_590951, "operation", newJString(operation))
  add(path_590949, "userId", newJString(userId))
  if body != nil:
    body_590952 = body
  add(path_590949, "accountId", newJString(accountId))
  result = call_590948.call(path_590949, query_590951, nil, nil, body_590952)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_590703(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_590704, base: "/",
    url: url_AssociatePhoneNumberWithUser_590705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_590991 = ref object of OpenApiRestCall_590364
proc url_AssociatePhoneNumbersWithVoiceConnector_590993(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnector_590992(path: JsonNode;
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
  var valid_590994 = path.getOrDefault("voiceConnectorId")
  valid_590994 = validateParameter(valid_590994, JString, required = true,
                                 default = nil)
  if valid_590994 != nil:
    section.add "voiceConnectorId", valid_590994
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_590995 = query.getOrDefault("operation")
  valid_590995 = validateParameter(valid_590995, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_590995 != nil:
    section.add "operation", valid_590995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590996 = header.getOrDefault("X-Amz-Signature")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Signature", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Content-Sha256", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-Date")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-Date", valid_590998
  var valid_590999 = header.getOrDefault("X-Amz-Credential")
  valid_590999 = validateParameter(valid_590999, JString, required = false,
                                 default = nil)
  if valid_590999 != nil:
    section.add "X-Amz-Credential", valid_590999
  var valid_591000 = header.getOrDefault("X-Amz-Security-Token")
  valid_591000 = validateParameter(valid_591000, JString, required = false,
                                 default = nil)
  if valid_591000 != nil:
    section.add "X-Amz-Security-Token", valid_591000
  var valid_591001 = header.getOrDefault("X-Amz-Algorithm")
  valid_591001 = validateParameter(valid_591001, JString, required = false,
                                 default = nil)
  if valid_591001 != nil:
    section.add "X-Amz-Algorithm", valid_591001
  var valid_591002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591002 = validateParameter(valid_591002, JString, required = false,
                                 default = nil)
  if valid_591002 != nil:
    section.add "X-Amz-SignedHeaders", valid_591002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591004: Call_AssociatePhoneNumbersWithVoiceConnector_590991;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591004.validator(path, query, header, formData, body)
  let scheme = call_591004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591004.url(scheme.get, call_591004.host, call_591004.base,
                         call_591004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591004, url, valid)

proc call*(call_591005: Call_AssociatePhoneNumbersWithVoiceConnector_590991;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591006 = newJObject()
  var query_591007 = newJObject()
  var body_591008 = newJObject()
  add(query_591007, "operation", newJString(operation))
  add(path_591006, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591008 = body
  result = call_591005.call(path_591006, query_591007, nil, nil, body_591008)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_590991(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_590992, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_590993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnectorGroup_591009 = ref object of OpenApiRestCall_590364
proc url_AssociatePhoneNumbersWithVoiceConnectorGroup_591011(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_AssociatePhoneNumbersWithVoiceConnectorGroup_591010(path: JsonNode;
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
  var valid_591012 = path.getOrDefault("voiceConnectorGroupId")
  valid_591012 = validateParameter(valid_591012, JString, required = true,
                                 default = nil)
  if valid_591012 != nil:
    section.add "voiceConnectorGroupId", valid_591012
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591013 = query.getOrDefault("operation")
  valid_591013 = validateParameter(valid_591013, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_591013 != nil:
    section.add "operation", valid_591013
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591014 = header.getOrDefault("X-Amz-Signature")
  valid_591014 = validateParameter(valid_591014, JString, required = false,
                                 default = nil)
  if valid_591014 != nil:
    section.add "X-Amz-Signature", valid_591014
  var valid_591015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591015 = validateParameter(valid_591015, JString, required = false,
                                 default = nil)
  if valid_591015 != nil:
    section.add "X-Amz-Content-Sha256", valid_591015
  var valid_591016 = header.getOrDefault("X-Amz-Date")
  valid_591016 = validateParameter(valid_591016, JString, required = false,
                                 default = nil)
  if valid_591016 != nil:
    section.add "X-Amz-Date", valid_591016
  var valid_591017 = header.getOrDefault("X-Amz-Credential")
  valid_591017 = validateParameter(valid_591017, JString, required = false,
                                 default = nil)
  if valid_591017 != nil:
    section.add "X-Amz-Credential", valid_591017
  var valid_591018 = header.getOrDefault("X-Amz-Security-Token")
  valid_591018 = validateParameter(valid_591018, JString, required = false,
                                 default = nil)
  if valid_591018 != nil:
    section.add "X-Amz-Security-Token", valid_591018
  var valid_591019 = header.getOrDefault("X-Amz-Algorithm")
  valid_591019 = validateParameter(valid_591019, JString, required = false,
                                 default = nil)
  if valid_591019 != nil:
    section.add "X-Amz-Algorithm", valid_591019
  var valid_591020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591020 = validateParameter(valid_591020, JString, required = false,
                                 default = nil)
  if valid_591020 != nil:
    section.add "X-Amz-SignedHeaders", valid_591020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591022: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_591009;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_591022.validator(path, query, header, formData, body)
  let scheme = call_591022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591022.url(scheme.get, call_591022.host, call_591022.base,
                         call_591022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591022, url, valid)

proc call*(call_591023: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_591009;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnectorGroup
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_591024 = newJObject()
  var query_591025 = newJObject()
  var body_591026 = newJObject()
  add(path_591024, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_591025, "operation", newJString(operation))
  if body != nil:
    body_591026 = body
  result = call_591023.call(path_591024, query_591025, nil, nil, body_591026)

var associatePhoneNumbersWithVoiceConnectorGroup* = Call_AssociatePhoneNumbersWithVoiceConnectorGroup_591009(
    name: "associatePhoneNumbersWithVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnectorGroup_591010,
    base: "/", url: url_AssociatePhoneNumbersWithVoiceConnectorGroup_591011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_591027 = ref object of OpenApiRestCall_590364
proc url_BatchDeletePhoneNumber_591029(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeletePhoneNumber_591028(path: JsonNode; query: JsonNode;
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
  var valid_591030 = query.getOrDefault("operation")
  valid_591030 = validateParameter(valid_591030, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_591030 != nil:
    section.add "operation", valid_591030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591031 = header.getOrDefault("X-Amz-Signature")
  valid_591031 = validateParameter(valid_591031, JString, required = false,
                                 default = nil)
  if valid_591031 != nil:
    section.add "X-Amz-Signature", valid_591031
  var valid_591032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591032 = validateParameter(valid_591032, JString, required = false,
                                 default = nil)
  if valid_591032 != nil:
    section.add "X-Amz-Content-Sha256", valid_591032
  var valid_591033 = header.getOrDefault("X-Amz-Date")
  valid_591033 = validateParameter(valid_591033, JString, required = false,
                                 default = nil)
  if valid_591033 != nil:
    section.add "X-Amz-Date", valid_591033
  var valid_591034 = header.getOrDefault("X-Amz-Credential")
  valid_591034 = validateParameter(valid_591034, JString, required = false,
                                 default = nil)
  if valid_591034 != nil:
    section.add "X-Amz-Credential", valid_591034
  var valid_591035 = header.getOrDefault("X-Amz-Security-Token")
  valid_591035 = validateParameter(valid_591035, JString, required = false,
                                 default = nil)
  if valid_591035 != nil:
    section.add "X-Amz-Security-Token", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Algorithm")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Algorithm", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-SignedHeaders", valid_591037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591039: Call_BatchDeletePhoneNumber_591027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_591039.validator(path, query, header, formData, body)
  let scheme = call_591039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591039.url(scheme.get, call_591039.host, call_591039.base,
                         call_591039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591039, url, valid)

proc call*(call_591040: Call_BatchDeletePhoneNumber_591027; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_591041 = newJObject()
  var body_591042 = newJObject()
  add(query_591041, "operation", newJString(operation))
  if body != nil:
    body_591042 = body
  result = call_591040.call(nil, query_591041, nil, nil, body_591042)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_591027(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_591028, base: "/",
    url: url_BatchDeletePhoneNumber_591029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_591043 = ref object of OpenApiRestCall_590364
proc url_BatchSuspendUser_591045(protocol: Scheme; host: string; base: string;
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

proc validate_BatchSuspendUser_591044(path: JsonNode; query: JsonNode;
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
  var valid_591046 = path.getOrDefault("accountId")
  valid_591046 = validateParameter(valid_591046, JString, required = true,
                                 default = nil)
  if valid_591046 != nil:
    section.add "accountId", valid_591046
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591047 = query.getOrDefault("operation")
  valid_591047 = validateParameter(valid_591047, JString, required = true,
                                 default = newJString("suspend"))
  if valid_591047 != nil:
    section.add "operation", valid_591047
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591048 = header.getOrDefault("X-Amz-Signature")
  valid_591048 = validateParameter(valid_591048, JString, required = false,
                                 default = nil)
  if valid_591048 != nil:
    section.add "X-Amz-Signature", valid_591048
  var valid_591049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591049 = validateParameter(valid_591049, JString, required = false,
                                 default = nil)
  if valid_591049 != nil:
    section.add "X-Amz-Content-Sha256", valid_591049
  var valid_591050 = header.getOrDefault("X-Amz-Date")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "X-Amz-Date", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-Credential")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Credential", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Security-Token")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Security-Token", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Algorithm")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Algorithm", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-SignedHeaders", valid_591054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591056: Call_BatchSuspendUser_591043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_591056.validator(path, query, header, formData, body)
  let scheme = call_591056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591056.url(scheme.get, call_591056.host, call_591056.base,
                         call_591056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591056, url, valid)

proc call*(call_591057: Call_BatchSuspendUser_591043; body: JsonNode;
          accountId: string; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591058 = newJObject()
  var query_591059 = newJObject()
  var body_591060 = newJObject()
  add(query_591059, "operation", newJString(operation))
  if body != nil:
    body_591060 = body
  add(path_591058, "accountId", newJString(accountId))
  result = call_591057.call(path_591058, query_591059, nil, nil, body_591060)

var batchSuspendUser* = Call_BatchSuspendUser_591043(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_591044, base: "/",
    url: url_BatchSuspendUser_591045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_591061 = ref object of OpenApiRestCall_590364
proc url_BatchUnsuspendUser_591063(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUnsuspendUser_591062(path: JsonNode; query: JsonNode;
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
  var valid_591064 = path.getOrDefault("accountId")
  valid_591064 = validateParameter(valid_591064, JString, required = true,
                                 default = nil)
  if valid_591064 != nil:
    section.add "accountId", valid_591064
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591065 = query.getOrDefault("operation")
  valid_591065 = validateParameter(valid_591065, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_591065 != nil:
    section.add "operation", valid_591065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_BatchUnsuspendUser_591061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_BatchUnsuspendUser_591061; body: JsonNode;
          accountId: string; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591076 = newJObject()
  var query_591077 = newJObject()
  var body_591078 = newJObject()
  add(query_591077, "operation", newJString(operation))
  if body != nil:
    body_591078 = body
  add(path_591076, "accountId", newJString(accountId))
  result = call_591075.call(path_591076, query_591077, nil, nil, body_591078)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_591061(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_591062, base: "/",
    url: url_BatchUnsuspendUser_591063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_591079 = ref object of OpenApiRestCall_590364
proc url_BatchUpdatePhoneNumber_591081(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchUpdatePhoneNumber_591080(path: JsonNode; query: JsonNode;
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
  var valid_591082 = query.getOrDefault("operation")
  valid_591082 = validateParameter(valid_591082, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_591082 != nil:
    section.add "operation", valid_591082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591083 = header.getOrDefault("X-Amz-Signature")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Signature", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Content-Sha256", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Date")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Date", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Credential")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Credential", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-Security-Token")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-Security-Token", valid_591087
  var valid_591088 = header.getOrDefault("X-Amz-Algorithm")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-Algorithm", valid_591088
  var valid_591089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-SignedHeaders", valid_591089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591091: Call_BatchUpdatePhoneNumber_591079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_591091.validator(path, query, header, formData, body)
  let scheme = call_591091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591091.url(scheme.get, call_591091.host, call_591091.base,
                         call_591091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591091, url, valid)

proc call*(call_591092: Call_BatchUpdatePhoneNumber_591079; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_591093 = newJObject()
  var body_591094 = newJObject()
  add(query_591093, "operation", newJString(operation))
  if body != nil:
    body_591094 = body
  result = call_591092.call(nil, query_591093, nil, nil, body_591094)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_591079(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_591080, base: "/",
    url: url_BatchUpdatePhoneNumber_591081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_591115 = ref object of OpenApiRestCall_590364
proc url_BatchUpdateUser_591117(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateUser_591116(path: JsonNode; query: JsonNode;
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
  var valid_591118 = path.getOrDefault("accountId")
  valid_591118 = validateParameter(valid_591118, JString, required = true,
                                 default = nil)
  if valid_591118 != nil:
    section.add "accountId", valid_591118
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591119 = header.getOrDefault("X-Amz-Signature")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "X-Amz-Signature", valid_591119
  var valid_591120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "X-Amz-Content-Sha256", valid_591120
  var valid_591121 = header.getOrDefault("X-Amz-Date")
  valid_591121 = validateParameter(valid_591121, JString, required = false,
                                 default = nil)
  if valid_591121 != nil:
    section.add "X-Amz-Date", valid_591121
  var valid_591122 = header.getOrDefault("X-Amz-Credential")
  valid_591122 = validateParameter(valid_591122, JString, required = false,
                                 default = nil)
  if valid_591122 != nil:
    section.add "X-Amz-Credential", valid_591122
  var valid_591123 = header.getOrDefault("X-Amz-Security-Token")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "X-Amz-Security-Token", valid_591123
  var valid_591124 = header.getOrDefault("X-Amz-Algorithm")
  valid_591124 = validateParameter(valid_591124, JString, required = false,
                                 default = nil)
  if valid_591124 != nil:
    section.add "X-Amz-Algorithm", valid_591124
  var valid_591125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "X-Amz-SignedHeaders", valid_591125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591127: Call_BatchUpdateUser_591115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_591127.validator(path, query, header, formData, body)
  let scheme = call_591127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591127.url(scheme.get, call_591127.host, call_591127.base,
                         call_591127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591127, url, valid)

proc call*(call_591128: Call_BatchUpdateUser_591115; body: JsonNode;
          accountId: string): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591129 = newJObject()
  var body_591130 = newJObject()
  if body != nil:
    body_591130 = body
  add(path_591129, "accountId", newJString(accountId))
  result = call_591128.call(path_591129, nil, nil, nil, body_591130)

var batchUpdateUser* = Call_BatchUpdateUser_591115(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_591116,
    base: "/", url: url_BatchUpdateUser_591117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_591095 = ref object of OpenApiRestCall_590364
proc url_ListUsers_591097(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_591096(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591098 = path.getOrDefault("accountId")
  valid_591098 = validateParameter(valid_591098, JString, required = true,
                                 default = nil)
  if valid_591098 != nil:
    section.add "accountId", valid_591098
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
  var valid_591099 = query.getOrDefault("MaxResults")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "MaxResults", valid_591099
  var valid_591100 = query.getOrDefault("user-email")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "user-email", valid_591100
  var valid_591101 = query.getOrDefault("NextToken")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "NextToken", valid_591101
  var valid_591102 = query.getOrDefault("max-results")
  valid_591102 = validateParameter(valid_591102, JInt, required = false, default = nil)
  if valid_591102 != nil:
    section.add "max-results", valid_591102
  var valid_591103 = query.getOrDefault("next-token")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "next-token", valid_591103
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591104 = header.getOrDefault("X-Amz-Signature")
  valid_591104 = validateParameter(valid_591104, JString, required = false,
                                 default = nil)
  if valid_591104 != nil:
    section.add "X-Amz-Signature", valid_591104
  var valid_591105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591105 = validateParameter(valid_591105, JString, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "X-Amz-Content-Sha256", valid_591105
  var valid_591106 = header.getOrDefault("X-Amz-Date")
  valid_591106 = validateParameter(valid_591106, JString, required = false,
                                 default = nil)
  if valid_591106 != nil:
    section.add "X-Amz-Date", valid_591106
  var valid_591107 = header.getOrDefault("X-Amz-Credential")
  valid_591107 = validateParameter(valid_591107, JString, required = false,
                                 default = nil)
  if valid_591107 != nil:
    section.add "X-Amz-Credential", valid_591107
  var valid_591108 = header.getOrDefault("X-Amz-Security-Token")
  valid_591108 = validateParameter(valid_591108, JString, required = false,
                                 default = nil)
  if valid_591108 != nil:
    section.add "X-Amz-Security-Token", valid_591108
  var valid_591109 = header.getOrDefault("X-Amz-Algorithm")
  valid_591109 = validateParameter(valid_591109, JString, required = false,
                                 default = nil)
  if valid_591109 != nil:
    section.add "X-Amz-Algorithm", valid_591109
  var valid_591110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-SignedHeaders", valid_591110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591111: Call_ListUsers_591095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_591111.validator(path, query, header, formData, body)
  let scheme = call_591111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591111.url(scheme.get, call_591111.host, call_591111.base,
                         call_591111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591111, url, valid)

proc call*(call_591112: Call_ListUsers_591095; accountId: string;
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
  var path_591113 = newJObject()
  var query_591114 = newJObject()
  add(query_591114, "MaxResults", newJString(MaxResults))
  add(query_591114, "user-email", newJString(userEmail))
  add(query_591114, "NextToken", newJString(NextToken))
  add(query_591114, "max-results", newJInt(maxResults))
  add(path_591113, "accountId", newJString(accountId))
  add(query_591114, "next-token", newJString(nextToken))
  result = call_591112.call(path_591113, query_591114, nil, nil, nil)

var listUsers* = Call_ListUsers_591095(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_591096,
                                    base: "/", url: url_ListUsers_591097,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_591150 = ref object of OpenApiRestCall_590364
proc url_CreateAccount_591152(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAccount_591151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591153 = header.getOrDefault("X-Amz-Signature")
  valid_591153 = validateParameter(valid_591153, JString, required = false,
                                 default = nil)
  if valid_591153 != nil:
    section.add "X-Amz-Signature", valid_591153
  var valid_591154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591154 = validateParameter(valid_591154, JString, required = false,
                                 default = nil)
  if valid_591154 != nil:
    section.add "X-Amz-Content-Sha256", valid_591154
  var valid_591155 = header.getOrDefault("X-Amz-Date")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Date", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Credential")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Credential", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Security-Token")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Security-Token", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Algorithm")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Algorithm", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-SignedHeaders", valid_591159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591161: Call_CreateAccount_591150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_591161.validator(path, query, header, formData, body)
  let scheme = call_591161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591161.url(scheme.get, call_591161.host, call_591161.base,
                         call_591161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591161, url, valid)

proc call*(call_591162: Call_CreateAccount_591150; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_591163 = newJObject()
  if body != nil:
    body_591163 = body
  result = call_591162.call(nil, nil, nil, nil, body_591163)

var createAccount* = Call_CreateAccount_591150(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_591151, base: "/", url: url_CreateAccount_591152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_591131 = ref object of OpenApiRestCall_590364
proc url_ListAccounts_591133(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAccounts_591132(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591134 = query.getOrDefault("name")
  valid_591134 = validateParameter(valid_591134, JString, required = false,
                                 default = nil)
  if valid_591134 != nil:
    section.add "name", valid_591134
  var valid_591135 = query.getOrDefault("MaxResults")
  valid_591135 = validateParameter(valid_591135, JString, required = false,
                                 default = nil)
  if valid_591135 != nil:
    section.add "MaxResults", valid_591135
  var valid_591136 = query.getOrDefault("user-email")
  valid_591136 = validateParameter(valid_591136, JString, required = false,
                                 default = nil)
  if valid_591136 != nil:
    section.add "user-email", valid_591136
  var valid_591137 = query.getOrDefault("NextToken")
  valid_591137 = validateParameter(valid_591137, JString, required = false,
                                 default = nil)
  if valid_591137 != nil:
    section.add "NextToken", valid_591137
  var valid_591138 = query.getOrDefault("max-results")
  valid_591138 = validateParameter(valid_591138, JInt, required = false, default = nil)
  if valid_591138 != nil:
    section.add "max-results", valid_591138
  var valid_591139 = query.getOrDefault("next-token")
  valid_591139 = validateParameter(valid_591139, JString, required = false,
                                 default = nil)
  if valid_591139 != nil:
    section.add "next-token", valid_591139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591140 = header.getOrDefault("X-Amz-Signature")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Signature", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Content-Sha256", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Date")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Date", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Credential")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Credential", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Security-Token")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Security-Token", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Algorithm")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Algorithm", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-SignedHeaders", valid_591146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591147: Call_ListAccounts_591131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_591147.validator(path, query, header, formData, body)
  let scheme = call_591147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591147.url(scheme.get, call_591147.host, call_591147.base,
                         call_591147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591147, url, valid)

proc call*(call_591148: Call_ListAccounts_591131; name: string = "";
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
  var query_591149 = newJObject()
  add(query_591149, "name", newJString(name))
  add(query_591149, "MaxResults", newJString(MaxResults))
  add(query_591149, "user-email", newJString(userEmail))
  add(query_591149, "NextToken", newJString(NextToken))
  add(query_591149, "max-results", newJInt(maxResults))
  add(query_591149, "next-token", newJString(nextToken))
  result = call_591148.call(nil, query_591149, nil, nil, nil)

var listAccounts* = Call_ListAccounts_591131(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_591132, base: "/", url: url_ListAccounts_591133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_591183 = ref object of OpenApiRestCall_590364
proc url_CreateBot_591185(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateBot_591184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591186 = path.getOrDefault("accountId")
  valid_591186 = validateParameter(valid_591186, JString, required = true,
                                 default = nil)
  if valid_591186 != nil:
    section.add "accountId", valid_591186
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591187 = header.getOrDefault("X-Amz-Signature")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Signature", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Content-Sha256", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Date")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Date", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Credential")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Credential", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Security-Token")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Security-Token", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-Algorithm")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-Algorithm", valid_591192
  var valid_591193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591193 = validateParameter(valid_591193, JString, required = false,
                                 default = nil)
  if valid_591193 != nil:
    section.add "X-Amz-SignedHeaders", valid_591193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591195: Call_CreateBot_591183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_591195.validator(path, query, header, formData, body)
  let scheme = call_591195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591195.url(scheme.get, call_591195.host, call_591195.base,
                         call_591195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591195, url, valid)

proc call*(call_591196: Call_CreateBot_591183; body: JsonNode; accountId: string): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591197 = newJObject()
  var body_591198 = newJObject()
  if body != nil:
    body_591198 = body
  add(path_591197, "accountId", newJString(accountId))
  result = call_591196.call(path_591197, nil, nil, nil, body_591198)

var createBot* = Call_CreateBot_591183(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_591184,
                                    base: "/", url: url_CreateBot_591185,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_591164 = ref object of OpenApiRestCall_590364
proc url_ListBots_591166(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListBots_591165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591167 = path.getOrDefault("accountId")
  valid_591167 = validateParameter(valid_591167, JString, required = true,
                                 default = nil)
  if valid_591167 != nil:
    section.add "accountId", valid_591167
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Default is 10.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_591168 = query.getOrDefault("MaxResults")
  valid_591168 = validateParameter(valid_591168, JString, required = false,
                                 default = nil)
  if valid_591168 != nil:
    section.add "MaxResults", valid_591168
  var valid_591169 = query.getOrDefault("NextToken")
  valid_591169 = validateParameter(valid_591169, JString, required = false,
                                 default = nil)
  if valid_591169 != nil:
    section.add "NextToken", valid_591169
  var valid_591170 = query.getOrDefault("max-results")
  valid_591170 = validateParameter(valid_591170, JInt, required = false, default = nil)
  if valid_591170 != nil:
    section.add "max-results", valid_591170
  var valid_591171 = query.getOrDefault("next-token")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "next-token", valid_591171
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591172 = header.getOrDefault("X-Amz-Signature")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Signature", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Content-Sha256", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Date")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Date", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Credential")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Credential", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Security-Token")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Security-Token", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-Algorithm")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-Algorithm", valid_591177
  var valid_591178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591178 = validateParameter(valid_591178, JString, required = false,
                                 default = nil)
  if valid_591178 != nil:
    section.add "X-Amz-SignedHeaders", valid_591178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591179: Call_ListBots_591164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_591179.validator(path, query, header, formData, body)
  let scheme = call_591179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591179.url(scheme.get, call_591179.host, call_591179.base,
                         call_591179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591179, url, valid)

proc call*(call_591180: Call_ListBots_591164; accountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBots
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Default is 10.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_591181 = newJObject()
  var query_591182 = newJObject()
  add(query_591182, "MaxResults", newJString(MaxResults))
  add(query_591182, "NextToken", newJString(NextToken))
  add(query_591182, "max-results", newJInt(maxResults))
  add(path_591181, "accountId", newJString(accountId))
  add(query_591182, "next-token", newJString(nextToken))
  result = call_591180.call(path_591181, query_591182, nil, nil, nil)

var listBots* = Call_ListBots_591164(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_591165, base: "/",
                                  url: url_ListBots_591166,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_591216 = ref object of OpenApiRestCall_590364
proc url_CreatePhoneNumberOrder_591218(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePhoneNumberOrder_591217(path: JsonNode; query: JsonNode;
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
  var valid_591219 = header.getOrDefault("X-Amz-Signature")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Signature", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-Content-Sha256", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Date")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Date", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-Credential")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-Credential", valid_591222
  var valid_591223 = header.getOrDefault("X-Amz-Security-Token")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Security-Token", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-Algorithm")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-Algorithm", valid_591224
  var valid_591225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "X-Amz-SignedHeaders", valid_591225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591227: Call_CreatePhoneNumberOrder_591216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_591227.validator(path, query, header, formData, body)
  let scheme = call_591227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591227.url(scheme.get, call_591227.host, call_591227.base,
                         call_591227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591227, url, valid)

proc call*(call_591228: Call_CreatePhoneNumberOrder_591216; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_591229 = newJObject()
  if body != nil:
    body_591229 = body
  result = call_591228.call(nil, nil, nil, nil, body_591229)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_591216(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_591217, base: "/",
    url: url_CreatePhoneNumberOrder_591218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_591199 = ref object of OpenApiRestCall_590364
proc url_ListPhoneNumberOrders_591201(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPhoneNumberOrders_591200(path: JsonNode; query: JsonNode;
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
  var valid_591202 = query.getOrDefault("MaxResults")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "MaxResults", valid_591202
  var valid_591203 = query.getOrDefault("NextToken")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "NextToken", valid_591203
  var valid_591204 = query.getOrDefault("max-results")
  valid_591204 = validateParameter(valid_591204, JInt, required = false, default = nil)
  if valid_591204 != nil:
    section.add "max-results", valid_591204
  var valid_591205 = query.getOrDefault("next-token")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "next-token", valid_591205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591206 = header.getOrDefault("X-Amz-Signature")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Signature", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-Content-Sha256", valid_591207
  var valid_591208 = header.getOrDefault("X-Amz-Date")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Date", valid_591208
  var valid_591209 = header.getOrDefault("X-Amz-Credential")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amz-Credential", valid_591209
  var valid_591210 = header.getOrDefault("X-Amz-Security-Token")
  valid_591210 = validateParameter(valid_591210, JString, required = false,
                                 default = nil)
  if valid_591210 != nil:
    section.add "X-Amz-Security-Token", valid_591210
  var valid_591211 = header.getOrDefault("X-Amz-Algorithm")
  valid_591211 = validateParameter(valid_591211, JString, required = false,
                                 default = nil)
  if valid_591211 != nil:
    section.add "X-Amz-Algorithm", valid_591211
  var valid_591212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-SignedHeaders", valid_591212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591213: Call_ListPhoneNumberOrders_591199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_591213.validator(path, query, header, formData, body)
  let scheme = call_591213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591213.url(scheme.get, call_591213.host, call_591213.base,
                         call_591213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591213, url, valid)

proc call*(call_591214: Call_ListPhoneNumberOrders_591199; MaxResults: string = "";
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
  var query_591215 = newJObject()
  add(query_591215, "MaxResults", newJString(MaxResults))
  add(query_591215, "NextToken", newJString(NextToken))
  add(query_591215, "max-results", newJInt(maxResults))
  add(query_591215, "next-token", newJString(nextToken))
  result = call_591214.call(nil, query_591215, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_591199(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_591200, base: "/",
    url: url_ListPhoneNumberOrders_591201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_591247 = ref object of OpenApiRestCall_590364
proc url_CreateVoiceConnector_591249(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVoiceConnector_591248(path: JsonNode; query: JsonNode;
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
  var valid_591250 = header.getOrDefault("X-Amz-Signature")
  valid_591250 = validateParameter(valid_591250, JString, required = false,
                                 default = nil)
  if valid_591250 != nil:
    section.add "X-Amz-Signature", valid_591250
  var valid_591251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-Content-Sha256", valid_591251
  var valid_591252 = header.getOrDefault("X-Amz-Date")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "X-Amz-Date", valid_591252
  var valid_591253 = header.getOrDefault("X-Amz-Credential")
  valid_591253 = validateParameter(valid_591253, JString, required = false,
                                 default = nil)
  if valid_591253 != nil:
    section.add "X-Amz-Credential", valid_591253
  var valid_591254 = header.getOrDefault("X-Amz-Security-Token")
  valid_591254 = validateParameter(valid_591254, JString, required = false,
                                 default = nil)
  if valid_591254 != nil:
    section.add "X-Amz-Security-Token", valid_591254
  var valid_591255 = header.getOrDefault("X-Amz-Algorithm")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "X-Amz-Algorithm", valid_591255
  var valid_591256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-SignedHeaders", valid_591256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591258: Call_CreateVoiceConnector_591247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  let valid = call_591258.validator(path, query, header, formData, body)
  let scheme = call_591258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591258.url(scheme.get, call_591258.host, call_591258.base,
                         call_591258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591258, url, valid)

proc call*(call_591259: Call_CreateVoiceConnector_591247; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ##   body: JObject (required)
  var body_591260 = newJObject()
  if body != nil:
    body_591260 = body
  result = call_591259.call(nil, nil, nil, nil, body_591260)

var createVoiceConnector* = Call_CreateVoiceConnector_591247(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_591248, base: "/",
    url: url_CreateVoiceConnector_591249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_591230 = ref object of OpenApiRestCall_590364
proc url_ListVoiceConnectors_591232(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVoiceConnectors_591231(path: JsonNode; query: JsonNode;
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
  var valid_591233 = query.getOrDefault("MaxResults")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "MaxResults", valid_591233
  var valid_591234 = query.getOrDefault("NextToken")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "NextToken", valid_591234
  var valid_591235 = query.getOrDefault("max-results")
  valid_591235 = validateParameter(valid_591235, JInt, required = false, default = nil)
  if valid_591235 != nil:
    section.add "max-results", valid_591235
  var valid_591236 = query.getOrDefault("next-token")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "next-token", valid_591236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591237 = header.getOrDefault("X-Amz-Signature")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "X-Amz-Signature", valid_591237
  var valid_591238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591238 = validateParameter(valid_591238, JString, required = false,
                                 default = nil)
  if valid_591238 != nil:
    section.add "X-Amz-Content-Sha256", valid_591238
  var valid_591239 = header.getOrDefault("X-Amz-Date")
  valid_591239 = validateParameter(valid_591239, JString, required = false,
                                 default = nil)
  if valid_591239 != nil:
    section.add "X-Amz-Date", valid_591239
  var valid_591240 = header.getOrDefault("X-Amz-Credential")
  valid_591240 = validateParameter(valid_591240, JString, required = false,
                                 default = nil)
  if valid_591240 != nil:
    section.add "X-Amz-Credential", valid_591240
  var valid_591241 = header.getOrDefault("X-Amz-Security-Token")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Security-Token", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-Algorithm")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Algorithm", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-SignedHeaders", valid_591243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591244: Call_ListVoiceConnectors_591230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_591244.validator(path, query, header, formData, body)
  let scheme = call_591244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591244.url(scheme.get, call_591244.host, call_591244.base,
                         call_591244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591244, url, valid)

proc call*(call_591245: Call_ListVoiceConnectors_591230; MaxResults: string = "";
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
  var query_591246 = newJObject()
  add(query_591246, "MaxResults", newJString(MaxResults))
  add(query_591246, "NextToken", newJString(NextToken))
  add(query_591246, "max-results", newJInt(maxResults))
  add(query_591246, "next-token", newJString(nextToken))
  result = call_591245.call(nil, query_591246, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_591230(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_591231, base: "/",
    url: url_ListVoiceConnectors_591232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnectorGroup_591278 = ref object of OpenApiRestCall_590364
proc url_CreateVoiceConnectorGroup_591280(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVoiceConnectorGroup_591279(path: JsonNode; query: JsonNode;
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
  var valid_591281 = header.getOrDefault("X-Amz-Signature")
  valid_591281 = validateParameter(valid_591281, JString, required = false,
                                 default = nil)
  if valid_591281 != nil:
    section.add "X-Amz-Signature", valid_591281
  var valid_591282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591282 = validateParameter(valid_591282, JString, required = false,
                                 default = nil)
  if valid_591282 != nil:
    section.add "X-Amz-Content-Sha256", valid_591282
  var valid_591283 = header.getOrDefault("X-Amz-Date")
  valid_591283 = validateParameter(valid_591283, JString, required = false,
                                 default = nil)
  if valid_591283 != nil:
    section.add "X-Amz-Date", valid_591283
  var valid_591284 = header.getOrDefault("X-Amz-Credential")
  valid_591284 = validateParameter(valid_591284, JString, required = false,
                                 default = nil)
  if valid_591284 != nil:
    section.add "X-Amz-Credential", valid_591284
  var valid_591285 = header.getOrDefault("X-Amz-Security-Token")
  valid_591285 = validateParameter(valid_591285, JString, required = false,
                                 default = nil)
  if valid_591285 != nil:
    section.add "X-Amz-Security-Token", valid_591285
  var valid_591286 = header.getOrDefault("X-Amz-Algorithm")
  valid_591286 = validateParameter(valid_591286, JString, required = false,
                                 default = nil)
  if valid_591286 != nil:
    section.add "X-Amz-Algorithm", valid_591286
  var valid_591287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591287 = validateParameter(valid_591287, JString, required = false,
                                 default = nil)
  if valid_591287 != nil:
    section.add "X-Amz-SignedHeaders", valid_591287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591289: Call_CreateVoiceConnectorGroup_591278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  let valid = call_591289.validator(path, query, header, formData, body)
  let scheme = call_591289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591289.url(scheme.get, call_591289.host, call_591289.base,
                         call_591289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591289, url, valid)

proc call*(call_591290: Call_CreateVoiceConnectorGroup_591278; body: JsonNode): Recallable =
  ## createVoiceConnectorGroup
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ##   body: JObject (required)
  var body_591291 = newJObject()
  if body != nil:
    body_591291 = body
  result = call_591290.call(nil, nil, nil, nil, body_591291)

var createVoiceConnectorGroup* = Call_CreateVoiceConnectorGroup_591278(
    name: "createVoiceConnectorGroup", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_CreateVoiceConnectorGroup_591279, base: "/",
    url: url_CreateVoiceConnectorGroup_591280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorGroups_591261 = ref object of OpenApiRestCall_590364
proc url_ListVoiceConnectorGroups_591263(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListVoiceConnectorGroups_591262(path: JsonNode; query: JsonNode;
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
  var valid_591264 = query.getOrDefault("MaxResults")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "MaxResults", valid_591264
  var valid_591265 = query.getOrDefault("NextToken")
  valid_591265 = validateParameter(valid_591265, JString, required = false,
                                 default = nil)
  if valid_591265 != nil:
    section.add "NextToken", valid_591265
  var valid_591266 = query.getOrDefault("max-results")
  valid_591266 = validateParameter(valid_591266, JInt, required = false, default = nil)
  if valid_591266 != nil:
    section.add "max-results", valid_591266
  var valid_591267 = query.getOrDefault("next-token")
  valid_591267 = validateParameter(valid_591267, JString, required = false,
                                 default = nil)
  if valid_591267 != nil:
    section.add "next-token", valid_591267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591268 = header.getOrDefault("X-Amz-Signature")
  valid_591268 = validateParameter(valid_591268, JString, required = false,
                                 default = nil)
  if valid_591268 != nil:
    section.add "X-Amz-Signature", valid_591268
  var valid_591269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591269 = validateParameter(valid_591269, JString, required = false,
                                 default = nil)
  if valid_591269 != nil:
    section.add "X-Amz-Content-Sha256", valid_591269
  var valid_591270 = header.getOrDefault("X-Amz-Date")
  valid_591270 = validateParameter(valid_591270, JString, required = false,
                                 default = nil)
  if valid_591270 != nil:
    section.add "X-Amz-Date", valid_591270
  var valid_591271 = header.getOrDefault("X-Amz-Credential")
  valid_591271 = validateParameter(valid_591271, JString, required = false,
                                 default = nil)
  if valid_591271 != nil:
    section.add "X-Amz-Credential", valid_591271
  var valid_591272 = header.getOrDefault("X-Amz-Security-Token")
  valid_591272 = validateParameter(valid_591272, JString, required = false,
                                 default = nil)
  if valid_591272 != nil:
    section.add "X-Amz-Security-Token", valid_591272
  var valid_591273 = header.getOrDefault("X-Amz-Algorithm")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "X-Amz-Algorithm", valid_591273
  var valid_591274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-SignedHeaders", valid_591274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591275: Call_ListVoiceConnectorGroups_591261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  let valid = call_591275.validator(path, query, header, formData, body)
  let scheme = call_591275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591275.url(scheme.get, call_591275.host, call_591275.base,
                         call_591275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591275, url, valid)

proc call*(call_591276: Call_ListVoiceConnectorGroups_591261;
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
  var query_591277 = newJObject()
  add(query_591277, "MaxResults", newJString(MaxResults))
  add(query_591277, "NextToken", newJString(NextToken))
  add(query_591277, "max-results", newJInt(maxResults))
  add(query_591277, "next-token", newJString(nextToken))
  result = call_591276.call(nil, query_591277, nil, nil, nil)

var listVoiceConnectorGroups* = Call_ListVoiceConnectorGroups_591261(
    name: "listVoiceConnectorGroups", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_ListVoiceConnectorGroups_591262, base: "/",
    url: url_ListVoiceConnectorGroups_591263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_591306 = ref object of OpenApiRestCall_590364
proc url_UpdateAccount_591308(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_591307(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591309 = path.getOrDefault("accountId")
  valid_591309 = validateParameter(valid_591309, JString, required = true,
                                 default = nil)
  if valid_591309 != nil:
    section.add "accountId", valid_591309
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591310 = header.getOrDefault("X-Amz-Signature")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Signature", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Content-Sha256", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-Date")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-Date", valid_591312
  var valid_591313 = header.getOrDefault("X-Amz-Credential")
  valid_591313 = validateParameter(valid_591313, JString, required = false,
                                 default = nil)
  if valid_591313 != nil:
    section.add "X-Amz-Credential", valid_591313
  var valid_591314 = header.getOrDefault("X-Amz-Security-Token")
  valid_591314 = validateParameter(valid_591314, JString, required = false,
                                 default = nil)
  if valid_591314 != nil:
    section.add "X-Amz-Security-Token", valid_591314
  var valid_591315 = header.getOrDefault("X-Amz-Algorithm")
  valid_591315 = validateParameter(valid_591315, JString, required = false,
                                 default = nil)
  if valid_591315 != nil:
    section.add "X-Amz-Algorithm", valid_591315
  var valid_591316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591316 = validateParameter(valid_591316, JString, required = false,
                                 default = nil)
  if valid_591316 != nil:
    section.add "X-Amz-SignedHeaders", valid_591316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591318: Call_UpdateAccount_591306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_591318.validator(path, query, header, formData, body)
  let scheme = call_591318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591318.url(scheme.get, call_591318.host, call_591318.base,
                         call_591318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591318, url, valid)

proc call*(call_591319: Call_UpdateAccount_591306; body: JsonNode; accountId: string): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591320 = newJObject()
  var body_591321 = newJObject()
  if body != nil:
    body_591321 = body
  add(path_591320, "accountId", newJString(accountId))
  result = call_591319.call(path_591320, nil, nil, nil, body_591321)

var updateAccount* = Call_UpdateAccount_591306(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_591307,
    base: "/", url: url_UpdateAccount_591308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_591292 = ref object of OpenApiRestCall_590364
proc url_GetAccount_591294(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_591293(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591295 = path.getOrDefault("accountId")
  valid_591295 = validateParameter(valid_591295, JString, required = true,
                                 default = nil)
  if valid_591295 != nil:
    section.add "accountId", valid_591295
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591296 = header.getOrDefault("X-Amz-Signature")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-Signature", valid_591296
  var valid_591297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591297 = validateParameter(valid_591297, JString, required = false,
                                 default = nil)
  if valid_591297 != nil:
    section.add "X-Amz-Content-Sha256", valid_591297
  var valid_591298 = header.getOrDefault("X-Amz-Date")
  valid_591298 = validateParameter(valid_591298, JString, required = false,
                                 default = nil)
  if valid_591298 != nil:
    section.add "X-Amz-Date", valid_591298
  var valid_591299 = header.getOrDefault("X-Amz-Credential")
  valid_591299 = validateParameter(valid_591299, JString, required = false,
                                 default = nil)
  if valid_591299 != nil:
    section.add "X-Amz-Credential", valid_591299
  var valid_591300 = header.getOrDefault("X-Amz-Security-Token")
  valid_591300 = validateParameter(valid_591300, JString, required = false,
                                 default = nil)
  if valid_591300 != nil:
    section.add "X-Amz-Security-Token", valid_591300
  var valid_591301 = header.getOrDefault("X-Amz-Algorithm")
  valid_591301 = validateParameter(valid_591301, JString, required = false,
                                 default = nil)
  if valid_591301 != nil:
    section.add "X-Amz-Algorithm", valid_591301
  var valid_591302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591302 = validateParameter(valid_591302, JString, required = false,
                                 default = nil)
  if valid_591302 != nil:
    section.add "X-Amz-SignedHeaders", valid_591302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591303: Call_GetAccount_591292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_591303.validator(path, query, header, formData, body)
  let scheme = call_591303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591303.url(scheme.get, call_591303.host, call_591303.base,
                         call_591303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591303, url, valid)

proc call*(call_591304: Call_GetAccount_591292; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591305 = newJObject()
  add(path_591305, "accountId", newJString(accountId))
  result = call_591304.call(path_591305, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_591292(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_591293,
                                      base: "/", url: url_GetAccount_591294,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_591322 = ref object of OpenApiRestCall_590364
proc url_DeleteAccount_591324(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccount_591323(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591325 = path.getOrDefault("accountId")
  valid_591325 = validateParameter(valid_591325, JString, required = true,
                                 default = nil)
  if valid_591325 != nil:
    section.add "accountId", valid_591325
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591326 = header.getOrDefault("X-Amz-Signature")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Signature", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-Content-Sha256", valid_591327
  var valid_591328 = header.getOrDefault("X-Amz-Date")
  valid_591328 = validateParameter(valid_591328, JString, required = false,
                                 default = nil)
  if valid_591328 != nil:
    section.add "X-Amz-Date", valid_591328
  var valid_591329 = header.getOrDefault("X-Amz-Credential")
  valid_591329 = validateParameter(valid_591329, JString, required = false,
                                 default = nil)
  if valid_591329 != nil:
    section.add "X-Amz-Credential", valid_591329
  var valid_591330 = header.getOrDefault("X-Amz-Security-Token")
  valid_591330 = validateParameter(valid_591330, JString, required = false,
                                 default = nil)
  if valid_591330 != nil:
    section.add "X-Amz-Security-Token", valid_591330
  var valid_591331 = header.getOrDefault("X-Amz-Algorithm")
  valid_591331 = validateParameter(valid_591331, JString, required = false,
                                 default = nil)
  if valid_591331 != nil:
    section.add "X-Amz-Algorithm", valid_591331
  var valid_591332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591332 = validateParameter(valid_591332, JString, required = false,
                                 default = nil)
  if valid_591332 != nil:
    section.add "X-Amz-SignedHeaders", valid_591332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591333: Call_DeleteAccount_591322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_591333.validator(path, query, header, formData, body)
  let scheme = call_591333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591333.url(scheme.get, call_591333.host, call_591333.base,
                         call_591333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591333, url, valid)

proc call*(call_591334: Call_DeleteAccount_591322; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591335 = newJObject()
  add(path_591335, "accountId", newJString(accountId))
  result = call_591334.call(path_591335, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_591322(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_591323,
    base: "/", url: url_DeleteAccount_591324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_591351 = ref object of OpenApiRestCall_590364
proc url_PutEventsConfiguration_591353(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventsConfiguration_591352(path: JsonNode; query: JsonNode;
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
  var valid_591354 = path.getOrDefault("botId")
  valid_591354 = validateParameter(valid_591354, JString, required = true,
                                 default = nil)
  if valid_591354 != nil:
    section.add "botId", valid_591354
  var valid_591355 = path.getOrDefault("accountId")
  valid_591355 = validateParameter(valid_591355, JString, required = true,
                                 default = nil)
  if valid_591355 != nil:
    section.add "accountId", valid_591355
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591356 = header.getOrDefault("X-Amz-Signature")
  valid_591356 = validateParameter(valid_591356, JString, required = false,
                                 default = nil)
  if valid_591356 != nil:
    section.add "X-Amz-Signature", valid_591356
  var valid_591357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591357 = validateParameter(valid_591357, JString, required = false,
                                 default = nil)
  if valid_591357 != nil:
    section.add "X-Amz-Content-Sha256", valid_591357
  var valid_591358 = header.getOrDefault("X-Amz-Date")
  valid_591358 = validateParameter(valid_591358, JString, required = false,
                                 default = nil)
  if valid_591358 != nil:
    section.add "X-Amz-Date", valid_591358
  var valid_591359 = header.getOrDefault("X-Amz-Credential")
  valid_591359 = validateParameter(valid_591359, JString, required = false,
                                 default = nil)
  if valid_591359 != nil:
    section.add "X-Amz-Credential", valid_591359
  var valid_591360 = header.getOrDefault("X-Amz-Security-Token")
  valid_591360 = validateParameter(valid_591360, JString, required = false,
                                 default = nil)
  if valid_591360 != nil:
    section.add "X-Amz-Security-Token", valid_591360
  var valid_591361 = header.getOrDefault("X-Amz-Algorithm")
  valid_591361 = validateParameter(valid_591361, JString, required = false,
                                 default = nil)
  if valid_591361 != nil:
    section.add "X-Amz-Algorithm", valid_591361
  var valid_591362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591362 = validateParameter(valid_591362, JString, required = false,
                                 default = nil)
  if valid_591362 != nil:
    section.add "X-Amz-SignedHeaders", valid_591362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591364: Call_PutEventsConfiguration_591351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_591364.validator(path, query, header, formData, body)
  let scheme = call_591364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591364.url(scheme.get, call_591364.host, call_591364.base,
                         call_591364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591364, url, valid)

proc call*(call_591365: Call_PutEventsConfiguration_591351; botId: string;
          body: JsonNode; accountId: string): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591366 = newJObject()
  var body_591367 = newJObject()
  add(path_591366, "botId", newJString(botId))
  if body != nil:
    body_591367 = body
  add(path_591366, "accountId", newJString(accountId))
  result = call_591365.call(path_591366, nil, nil, nil, body_591367)

var putEventsConfiguration* = Call_PutEventsConfiguration_591351(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_591352, base: "/",
    url: url_PutEventsConfiguration_591353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_591336 = ref object of OpenApiRestCall_590364
proc url_GetEventsConfiguration_591338(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventsConfiguration_591337(path: JsonNode; query: JsonNode;
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
  var valid_591339 = path.getOrDefault("botId")
  valid_591339 = validateParameter(valid_591339, JString, required = true,
                                 default = nil)
  if valid_591339 != nil:
    section.add "botId", valid_591339
  var valid_591340 = path.getOrDefault("accountId")
  valid_591340 = validateParameter(valid_591340, JString, required = true,
                                 default = nil)
  if valid_591340 != nil:
    section.add "accountId", valid_591340
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591341 = header.getOrDefault("X-Amz-Signature")
  valid_591341 = validateParameter(valid_591341, JString, required = false,
                                 default = nil)
  if valid_591341 != nil:
    section.add "X-Amz-Signature", valid_591341
  var valid_591342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "X-Amz-Content-Sha256", valid_591342
  var valid_591343 = header.getOrDefault("X-Amz-Date")
  valid_591343 = validateParameter(valid_591343, JString, required = false,
                                 default = nil)
  if valid_591343 != nil:
    section.add "X-Amz-Date", valid_591343
  var valid_591344 = header.getOrDefault("X-Amz-Credential")
  valid_591344 = validateParameter(valid_591344, JString, required = false,
                                 default = nil)
  if valid_591344 != nil:
    section.add "X-Amz-Credential", valid_591344
  var valid_591345 = header.getOrDefault("X-Amz-Security-Token")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "X-Amz-Security-Token", valid_591345
  var valid_591346 = header.getOrDefault("X-Amz-Algorithm")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Algorithm", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-SignedHeaders", valid_591347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591348: Call_GetEventsConfiguration_591336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_591348.validator(path, query, header, formData, body)
  let scheme = call_591348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591348.url(scheme.get, call_591348.host, call_591348.base,
                         call_591348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591348, url, valid)

proc call*(call_591349: Call_GetEventsConfiguration_591336; botId: string;
          accountId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591350 = newJObject()
  add(path_591350, "botId", newJString(botId))
  add(path_591350, "accountId", newJString(accountId))
  result = call_591349.call(path_591350, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_591336(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_591337, base: "/",
    url: url_GetEventsConfiguration_591338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_591368 = ref object of OpenApiRestCall_590364
proc url_DeleteEventsConfiguration_591370(protocol: Scheme; host: string;
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

proc validate_DeleteEventsConfiguration_591369(path: JsonNode; query: JsonNode;
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
  var valid_591371 = path.getOrDefault("botId")
  valid_591371 = validateParameter(valid_591371, JString, required = true,
                                 default = nil)
  if valid_591371 != nil:
    section.add "botId", valid_591371
  var valid_591372 = path.getOrDefault("accountId")
  valid_591372 = validateParameter(valid_591372, JString, required = true,
                                 default = nil)
  if valid_591372 != nil:
    section.add "accountId", valid_591372
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591373 = header.getOrDefault("X-Amz-Signature")
  valid_591373 = validateParameter(valid_591373, JString, required = false,
                                 default = nil)
  if valid_591373 != nil:
    section.add "X-Amz-Signature", valid_591373
  var valid_591374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591374 = validateParameter(valid_591374, JString, required = false,
                                 default = nil)
  if valid_591374 != nil:
    section.add "X-Amz-Content-Sha256", valid_591374
  var valid_591375 = header.getOrDefault("X-Amz-Date")
  valid_591375 = validateParameter(valid_591375, JString, required = false,
                                 default = nil)
  if valid_591375 != nil:
    section.add "X-Amz-Date", valid_591375
  var valid_591376 = header.getOrDefault("X-Amz-Credential")
  valid_591376 = validateParameter(valid_591376, JString, required = false,
                                 default = nil)
  if valid_591376 != nil:
    section.add "X-Amz-Credential", valid_591376
  var valid_591377 = header.getOrDefault("X-Amz-Security-Token")
  valid_591377 = validateParameter(valid_591377, JString, required = false,
                                 default = nil)
  if valid_591377 != nil:
    section.add "X-Amz-Security-Token", valid_591377
  var valid_591378 = header.getOrDefault("X-Amz-Algorithm")
  valid_591378 = validateParameter(valid_591378, JString, required = false,
                                 default = nil)
  if valid_591378 != nil:
    section.add "X-Amz-Algorithm", valid_591378
  var valid_591379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591379 = validateParameter(valid_591379, JString, required = false,
                                 default = nil)
  if valid_591379 != nil:
    section.add "X-Amz-SignedHeaders", valid_591379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591380: Call_DeleteEventsConfiguration_591368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_591380.validator(path, query, header, formData, body)
  let scheme = call_591380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591380.url(scheme.get, call_591380.host, call_591380.base,
                         call_591380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591380, url, valid)

proc call*(call_591381: Call_DeleteEventsConfiguration_591368; botId: string;
          accountId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591382 = newJObject()
  add(path_591382, "botId", newJString(botId))
  add(path_591382, "accountId", newJString(accountId))
  result = call_591381.call(path_591382, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_591368(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_591369, base: "/",
    url: url_DeleteEventsConfiguration_591370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_591397 = ref object of OpenApiRestCall_590364
proc url_UpdatePhoneNumber_591399(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePhoneNumber_591398(path: JsonNode; query: JsonNode;
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
  var valid_591400 = path.getOrDefault("phoneNumberId")
  valid_591400 = validateParameter(valid_591400, JString, required = true,
                                 default = nil)
  if valid_591400 != nil:
    section.add "phoneNumberId", valid_591400
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591401 = header.getOrDefault("X-Amz-Signature")
  valid_591401 = validateParameter(valid_591401, JString, required = false,
                                 default = nil)
  if valid_591401 != nil:
    section.add "X-Amz-Signature", valid_591401
  var valid_591402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591402 = validateParameter(valid_591402, JString, required = false,
                                 default = nil)
  if valid_591402 != nil:
    section.add "X-Amz-Content-Sha256", valid_591402
  var valid_591403 = header.getOrDefault("X-Amz-Date")
  valid_591403 = validateParameter(valid_591403, JString, required = false,
                                 default = nil)
  if valid_591403 != nil:
    section.add "X-Amz-Date", valid_591403
  var valid_591404 = header.getOrDefault("X-Amz-Credential")
  valid_591404 = validateParameter(valid_591404, JString, required = false,
                                 default = nil)
  if valid_591404 != nil:
    section.add "X-Amz-Credential", valid_591404
  var valid_591405 = header.getOrDefault("X-Amz-Security-Token")
  valid_591405 = validateParameter(valid_591405, JString, required = false,
                                 default = nil)
  if valid_591405 != nil:
    section.add "X-Amz-Security-Token", valid_591405
  var valid_591406 = header.getOrDefault("X-Amz-Algorithm")
  valid_591406 = validateParameter(valid_591406, JString, required = false,
                                 default = nil)
  if valid_591406 != nil:
    section.add "X-Amz-Algorithm", valid_591406
  var valid_591407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591407 = validateParameter(valid_591407, JString, required = false,
                                 default = nil)
  if valid_591407 != nil:
    section.add "X-Amz-SignedHeaders", valid_591407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591409: Call_UpdatePhoneNumber_591397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_591409.validator(path, query, header, formData, body)
  let scheme = call_591409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591409.url(scheme.get, call_591409.host, call_591409.base,
                         call_591409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591409, url, valid)

proc call*(call_591410: Call_UpdatePhoneNumber_591397; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_591411 = newJObject()
  var body_591412 = newJObject()
  add(path_591411, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_591412 = body
  result = call_591410.call(path_591411, nil, nil, nil, body_591412)

var updatePhoneNumber* = Call_UpdatePhoneNumber_591397(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_591398, base: "/",
    url: url_UpdatePhoneNumber_591399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_591383 = ref object of OpenApiRestCall_590364
proc url_GetPhoneNumber_591385(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumber_591384(path: JsonNode; query: JsonNode;
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
  var valid_591386 = path.getOrDefault("phoneNumberId")
  valid_591386 = validateParameter(valid_591386, JString, required = true,
                                 default = nil)
  if valid_591386 != nil:
    section.add "phoneNumberId", valid_591386
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591387 = header.getOrDefault("X-Amz-Signature")
  valid_591387 = validateParameter(valid_591387, JString, required = false,
                                 default = nil)
  if valid_591387 != nil:
    section.add "X-Amz-Signature", valid_591387
  var valid_591388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591388 = validateParameter(valid_591388, JString, required = false,
                                 default = nil)
  if valid_591388 != nil:
    section.add "X-Amz-Content-Sha256", valid_591388
  var valid_591389 = header.getOrDefault("X-Amz-Date")
  valid_591389 = validateParameter(valid_591389, JString, required = false,
                                 default = nil)
  if valid_591389 != nil:
    section.add "X-Amz-Date", valid_591389
  var valid_591390 = header.getOrDefault("X-Amz-Credential")
  valid_591390 = validateParameter(valid_591390, JString, required = false,
                                 default = nil)
  if valid_591390 != nil:
    section.add "X-Amz-Credential", valid_591390
  var valid_591391 = header.getOrDefault("X-Amz-Security-Token")
  valid_591391 = validateParameter(valid_591391, JString, required = false,
                                 default = nil)
  if valid_591391 != nil:
    section.add "X-Amz-Security-Token", valid_591391
  var valid_591392 = header.getOrDefault("X-Amz-Algorithm")
  valid_591392 = validateParameter(valid_591392, JString, required = false,
                                 default = nil)
  if valid_591392 != nil:
    section.add "X-Amz-Algorithm", valid_591392
  var valid_591393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591393 = validateParameter(valid_591393, JString, required = false,
                                 default = nil)
  if valid_591393 != nil:
    section.add "X-Amz-SignedHeaders", valid_591393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591394: Call_GetPhoneNumber_591383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_591394.validator(path, query, header, formData, body)
  let scheme = call_591394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591394.url(scheme.get, call_591394.host, call_591394.base,
                         call_591394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591394, url, valid)

proc call*(call_591395: Call_GetPhoneNumber_591383; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_591396 = newJObject()
  add(path_591396, "phoneNumberId", newJString(phoneNumberId))
  result = call_591395.call(path_591396, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_591383(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_591384,
    base: "/", url: url_GetPhoneNumber_591385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_591413 = ref object of OpenApiRestCall_590364
proc url_DeletePhoneNumber_591415(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePhoneNumber_591414(path: JsonNode; query: JsonNode;
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
  var valid_591416 = path.getOrDefault("phoneNumberId")
  valid_591416 = validateParameter(valid_591416, JString, required = true,
                                 default = nil)
  if valid_591416 != nil:
    section.add "phoneNumberId", valid_591416
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591417 = header.getOrDefault("X-Amz-Signature")
  valid_591417 = validateParameter(valid_591417, JString, required = false,
                                 default = nil)
  if valid_591417 != nil:
    section.add "X-Amz-Signature", valid_591417
  var valid_591418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591418 = validateParameter(valid_591418, JString, required = false,
                                 default = nil)
  if valid_591418 != nil:
    section.add "X-Amz-Content-Sha256", valid_591418
  var valid_591419 = header.getOrDefault("X-Amz-Date")
  valid_591419 = validateParameter(valid_591419, JString, required = false,
                                 default = nil)
  if valid_591419 != nil:
    section.add "X-Amz-Date", valid_591419
  var valid_591420 = header.getOrDefault("X-Amz-Credential")
  valid_591420 = validateParameter(valid_591420, JString, required = false,
                                 default = nil)
  if valid_591420 != nil:
    section.add "X-Amz-Credential", valid_591420
  var valid_591421 = header.getOrDefault("X-Amz-Security-Token")
  valid_591421 = validateParameter(valid_591421, JString, required = false,
                                 default = nil)
  if valid_591421 != nil:
    section.add "X-Amz-Security-Token", valid_591421
  var valid_591422 = header.getOrDefault("X-Amz-Algorithm")
  valid_591422 = validateParameter(valid_591422, JString, required = false,
                                 default = nil)
  if valid_591422 != nil:
    section.add "X-Amz-Algorithm", valid_591422
  var valid_591423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591423 = validateParameter(valid_591423, JString, required = false,
                                 default = nil)
  if valid_591423 != nil:
    section.add "X-Amz-SignedHeaders", valid_591423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591424: Call_DeletePhoneNumber_591413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_591424.validator(path, query, header, formData, body)
  let scheme = call_591424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591424.url(scheme.get, call_591424.host, call_591424.base,
                         call_591424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591424, url, valid)

proc call*(call_591425: Call_DeletePhoneNumber_591413; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_591426 = newJObject()
  add(path_591426, "phoneNumberId", newJString(phoneNumberId))
  result = call_591425.call(path_591426, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_591413(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_591414, base: "/",
    url: url_DeletePhoneNumber_591415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_591441 = ref object of OpenApiRestCall_590364
proc url_UpdateVoiceConnector_591443(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceConnector_591442(path: JsonNode; query: JsonNode;
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
  var valid_591444 = path.getOrDefault("voiceConnectorId")
  valid_591444 = validateParameter(valid_591444, JString, required = true,
                                 default = nil)
  if valid_591444 != nil:
    section.add "voiceConnectorId", valid_591444
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591445 = header.getOrDefault("X-Amz-Signature")
  valid_591445 = validateParameter(valid_591445, JString, required = false,
                                 default = nil)
  if valid_591445 != nil:
    section.add "X-Amz-Signature", valid_591445
  var valid_591446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591446 = validateParameter(valid_591446, JString, required = false,
                                 default = nil)
  if valid_591446 != nil:
    section.add "X-Amz-Content-Sha256", valid_591446
  var valid_591447 = header.getOrDefault("X-Amz-Date")
  valid_591447 = validateParameter(valid_591447, JString, required = false,
                                 default = nil)
  if valid_591447 != nil:
    section.add "X-Amz-Date", valid_591447
  var valid_591448 = header.getOrDefault("X-Amz-Credential")
  valid_591448 = validateParameter(valid_591448, JString, required = false,
                                 default = nil)
  if valid_591448 != nil:
    section.add "X-Amz-Credential", valid_591448
  var valid_591449 = header.getOrDefault("X-Amz-Security-Token")
  valid_591449 = validateParameter(valid_591449, JString, required = false,
                                 default = nil)
  if valid_591449 != nil:
    section.add "X-Amz-Security-Token", valid_591449
  var valid_591450 = header.getOrDefault("X-Amz-Algorithm")
  valid_591450 = validateParameter(valid_591450, JString, required = false,
                                 default = nil)
  if valid_591450 != nil:
    section.add "X-Amz-Algorithm", valid_591450
  var valid_591451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591451 = validateParameter(valid_591451, JString, required = false,
                                 default = nil)
  if valid_591451 != nil:
    section.add "X-Amz-SignedHeaders", valid_591451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591453: Call_UpdateVoiceConnector_591441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591453.validator(path, query, header, formData, body)
  let scheme = call_591453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591453.url(scheme.get, call_591453.host, call_591453.base,
                         call_591453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591453, url, valid)

proc call*(call_591454: Call_UpdateVoiceConnector_591441; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591455 = newJObject()
  var body_591456 = newJObject()
  add(path_591455, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591456 = body
  result = call_591454.call(path_591455, nil, nil, nil, body_591456)

var updateVoiceConnector* = Call_UpdateVoiceConnector_591441(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_591442, base: "/",
    url: url_UpdateVoiceConnector_591443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_591427 = ref object of OpenApiRestCall_590364
proc url_GetVoiceConnector_591429(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnector_591428(path: JsonNode; query: JsonNode;
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
  var valid_591430 = path.getOrDefault("voiceConnectorId")
  valid_591430 = validateParameter(valid_591430, JString, required = true,
                                 default = nil)
  if valid_591430 != nil:
    section.add "voiceConnectorId", valid_591430
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591431 = header.getOrDefault("X-Amz-Signature")
  valid_591431 = validateParameter(valid_591431, JString, required = false,
                                 default = nil)
  if valid_591431 != nil:
    section.add "X-Amz-Signature", valid_591431
  var valid_591432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591432 = validateParameter(valid_591432, JString, required = false,
                                 default = nil)
  if valid_591432 != nil:
    section.add "X-Amz-Content-Sha256", valid_591432
  var valid_591433 = header.getOrDefault("X-Amz-Date")
  valid_591433 = validateParameter(valid_591433, JString, required = false,
                                 default = nil)
  if valid_591433 != nil:
    section.add "X-Amz-Date", valid_591433
  var valid_591434 = header.getOrDefault("X-Amz-Credential")
  valid_591434 = validateParameter(valid_591434, JString, required = false,
                                 default = nil)
  if valid_591434 != nil:
    section.add "X-Amz-Credential", valid_591434
  var valid_591435 = header.getOrDefault("X-Amz-Security-Token")
  valid_591435 = validateParameter(valid_591435, JString, required = false,
                                 default = nil)
  if valid_591435 != nil:
    section.add "X-Amz-Security-Token", valid_591435
  var valid_591436 = header.getOrDefault("X-Amz-Algorithm")
  valid_591436 = validateParameter(valid_591436, JString, required = false,
                                 default = nil)
  if valid_591436 != nil:
    section.add "X-Amz-Algorithm", valid_591436
  var valid_591437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591437 = validateParameter(valid_591437, JString, required = false,
                                 default = nil)
  if valid_591437 != nil:
    section.add "X-Amz-SignedHeaders", valid_591437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591438: Call_GetVoiceConnector_591427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_591438.validator(path, query, header, formData, body)
  let scheme = call_591438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591438.url(scheme.get, call_591438.host, call_591438.base,
                         call_591438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591438, url, valid)

proc call*(call_591439: Call_GetVoiceConnector_591427; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591440 = newJObject()
  add(path_591440, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591439.call(path_591440, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_591427(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_591428, base: "/",
    url: url_GetVoiceConnector_591429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_591457 = ref object of OpenApiRestCall_590364
proc url_DeleteVoiceConnector_591459(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceConnector_591458(path: JsonNode; query: JsonNode;
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
  var valid_591460 = path.getOrDefault("voiceConnectorId")
  valid_591460 = validateParameter(valid_591460, JString, required = true,
                                 default = nil)
  if valid_591460 != nil:
    section.add "voiceConnectorId", valid_591460
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591461 = header.getOrDefault("X-Amz-Signature")
  valid_591461 = validateParameter(valid_591461, JString, required = false,
                                 default = nil)
  if valid_591461 != nil:
    section.add "X-Amz-Signature", valid_591461
  var valid_591462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591462 = validateParameter(valid_591462, JString, required = false,
                                 default = nil)
  if valid_591462 != nil:
    section.add "X-Amz-Content-Sha256", valid_591462
  var valid_591463 = header.getOrDefault("X-Amz-Date")
  valid_591463 = validateParameter(valid_591463, JString, required = false,
                                 default = nil)
  if valid_591463 != nil:
    section.add "X-Amz-Date", valid_591463
  var valid_591464 = header.getOrDefault("X-Amz-Credential")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "X-Amz-Credential", valid_591464
  var valid_591465 = header.getOrDefault("X-Amz-Security-Token")
  valid_591465 = validateParameter(valid_591465, JString, required = false,
                                 default = nil)
  if valid_591465 != nil:
    section.add "X-Amz-Security-Token", valid_591465
  var valid_591466 = header.getOrDefault("X-Amz-Algorithm")
  valid_591466 = validateParameter(valid_591466, JString, required = false,
                                 default = nil)
  if valid_591466 != nil:
    section.add "X-Amz-Algorithm", valid_591466
  var valid_591467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591467 = validateParameter(valid_591467, JString, required = false,
                                 default = nil)
  if valid_591467 != nil:
    section.add "X-Amz-SignedHeaders", valid_591467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591468: Call_DeleteVoiceConnector_591457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  let valid = call_591468.validator(path, query, header, formData, body)
  let scheme = call_591468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591468.url(scheme.get, call_591468.host, call_591468.base,
                         call_591468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591468, url, valid)

proc call*(call_591469: Call_DeleteVoiceConnector_591457; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591470 = newJObject()
  add(path_591470, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591469.call(path_591470, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_591457(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_591458, base: "/",
    url: url_DeleteVoiceConnector_591459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnectorGroup_591485 = ref object of OpenApiRestCall_590364
proc url_UpdateVoiceConnectorGroup_591487(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateVoiceConnectorGroup_591486(path: JsonNode; query: JsonNode;
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
  var valid_591488 = path.getOrDefault("voiceConnectorGroupId")
  valid_591488 = validateParameter(valid_591488, JString, required = true,
                                 default = nil)
  if valid_591488 != nil:
    section.add "voiceConnectorGroupId", valid_591488
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591489 = header.getOrDefault("X-Amz-Signature")
  valid_591489 = validateParameter(valid_591489, JString, required = false,
                                 default = nil)
  if valid_591489 != nil:
    section.add "X-Amz-Signature", valid_591489
  var valid_591490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591490 = validateParameter(valid_591490, JString, required = false,
                                 default = nil)
  if valid_591490 != nil:
    section.add "X-Amz-Content-Sha256", valid_591490
  var valid_591491 = header.getOrDefault("X-Amz-Date")
  valid_591491 = validateParameter(valid_591491, JString, required = false,
                                 default = nil)
  if valid_591491 != nil:
    section.add "X-Amz-Date", valid_591491
  var valid_591492 = header.getOrDefault("X-Amz-Credential")
  valid_591492 = validateParameter(valid_591492, JString, required = false,
                                 default = nil)
  if valid_591492 != nil:
    section.add "X-Amz-Credential", valid_591492
  var valid_591493 = header.getOrDefault("X-Amz-Security-Token")
  valid_591493 = validateParameter(valid_591493, JString, required = false,
                                 default = nil)
  if valid_591493 != nil:
    section.add "X-Amz-Security-Token", valid_591493
  var valid_591494 = header.getOrDefault("X-Amz-Algorithm")
  valid_591494 = validateParameter(valid_591494, JString, required = false,
                                 default = nil)
  if valid_591494 != nil:
    section.add "X-Amz-Algorithm", valid_591494
  var valid_591495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591495 = validateParameter(valid_591495, JString, required = false,
                                 default = nil)
  if valid_591495 != nil:
    section.add "X-Amz-SignedHeaders", valid_591495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591497: Call_UpdateVoiceConnectorGroup_591485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  let valid = call_591497.validator(path, query, header, formData, body)
  let scheme = call_591497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591497.url(scheme.get, call_591497.host, call_591497.base,
                         call_591497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591497, url, valid)

proc call*(call_591498: Call_UpdateVoiceConnectorGroup_591485;
          voiceConnectorGroupId: string; body: JsonNode): Recallable =
  ## updateVoiceConnectorGroup
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   body: JObject (required)
  var path_591499 = newJObject()
  var body_591500 = newJObject()
  add(path_591499, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  if body != nil:
    body_591500 = body
  result = call_591498.call(path_591499, nil, nil, nil, body_591500)

var updateVoiceConnectorGroup* = Call_UpdateVoiceConnectorGroup_591485(
    name: "updateVoiceConnectorGroup", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_UpdateVoiceConnectorGroup_591486, base: "/",
    url: url_UpdateVoiceConnectorGroup_591487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorGroup_591471 = ref object of OpenApiRestCall_590364
proc url_GetVoiceConnectorGroup_591473(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetVoiceConnectorGroup_591472(path: JsonNode; query: JsonNode;
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
  var valid_591474 = path.getOrDefault("voiceConnectorGroupId")
  valid_591474 = validateParameter(valid_591474, JString, required = true,
                                 default = nil)
  if valid_591474 != nil:
    section.add "voiceConnectorGroupId", valid_591474
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591475 = header.getOrDefault("X-Amz-Signature")
  valid_591475 = validateParameter(valid_591475, JString, required = false,
                                 default = nil)
  if valid_591475 != nil:
    section.add "X-Amz-Signature", valid_591475
  var valid_591476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591476 = validateParameter(valid_591476, JString, required = false,
                                 default = nil)
  if valid_591476 != nil:
    section.add "X-Amz-Content-Sha256", valid_591476
  var valid_591477 = header.getOrDefault("X-Amz-Date")
  valid_591477 = validateParameter(valid_591477, JString, required = false,
                                 default = nil)
  if valid_591477 != nil:
    section.add "X-Amz-Date", valid_591477
  var valid_591478 = header.getOrDefault("X-Amz-Credential")
  valid_591478 = validateParameter(valid_591478, JString, required = false,
                                 default = nil)
  if valid_591478 != nil:
    section.add "X-Amz-Credential", valid_591478
  var valid_591479 = header.getOrDefault("X-Amz-Security-Token")
  valid_591479 = validateParameter(valid_591479, JString, required = false,
                                 default = nil)
  if valid_591479 != nil:
    section.add "X-Amz-Security-Token", valid_591479
  var valid_591480 = header.getOrDefault("X-Amz-Algorithm")
  valid_591480 = validateParameter(valid_591480, JString, required = false,
                                 default = nil)
  if valid_591480 != nil:
    section.add "X-Amz-Algorithm", valid_591480
  var valid_591481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591481 = validateParameter(valid_591481, JString, required = false,
                                 default = nil)
  if valid_591481 != nil:
    section.add "X-Amz-SignedHeaders", valid_591481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591482: Call_GetVoiceConnectorGroup_591471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  let valid = call_591482.validator(path, query, header, formData, body)
  let scheme = call_591482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591482.url(scheme.get, call_591482.host, call_591482.base,
                         call_591482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591482, url, valid)

proc call*(call_591483: Call_GetVoiceConnectorGroup_591471;
          voiceConnectorGroupId: string): Recallable =
  ## getVoiceConnectorGroup
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_591484 = newJObject()
  add(path_591484, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_591483.call(path_591484, nil, nil, nil, nil)

var getVoiceConnectorGroup* = Call_GetVoiceConnectorGroup_591471(
    name: "getVoiceConnectorGroup", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_GetVoiceConnectorGroup_591472, base: "/",
    url: url_GetVoiceConnectorGroup_591473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorGroup_591501 = ref object of OpenApiRestCall_590364
proc url_DeleteVoiceConnectorGroup_591503(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorGroup_591502(path: JsonNode; query: JsonNode;
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
  var valid_591504 = path.getOrDefault("voiceConnectorGroupId")
  valid_591504 = validateParameter(valid_591504, JString, required = true,
                                 default = nil)
  if valid_591504 != nil:
    section.add "voiceConnectorGroupId", valid_591504
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591505 = header.getOrDefault("X-Amz-Signature")
  valid_591505 = validateParameter(valid_591505, JString, required = false,
                                 default = nil)
  if valid_591505 != nil:
    section.add "X-Amz-Signature", valid_591505
  var valid_591506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591506 = validateParameter(valid_591506, JString, required = false,
                                 default = nil)
  if valid_591506 != nil:
    section.add "X-Amz-Content-Sha256", valid_591506
  var valid_591507 = header.getOrDefault("X-Amz-Date")
  valid_591507 = validateParameter(valid_591507, JString, required = false,
                                 default = nil)
  if valid_591507 != nil:
    section.add "X-Amz-Date", valid_591507
  var valid_591508 = header.getOrDefault("X-Amz-Credential")
  valid_591508 = validateParameter(valid_591508, JString, required = false,
                                 default = nil)
  if valid_591508 != nil:
    section.add "X-Amz-Credential", valid_591508
  var valid_591509 = header.getOrDefault("X-Amz-Security-Token")
  valid_591509 = validateParameter(valid_591509, JString, required = false,
                                 default = nil)
  if valid_591509 != nil:
    section.add "X-Amz-Security-Token", valid_591509
  var valid_591510 = header.getOrDefault("X-Amz-Algorithm")
  valid_591510 = validateParameter(valid_591510, JString, required = false,
                                 default = nil)
  if valid_591510 != nil:
    section.add "X-Amz-Algorithm", valid_591510
  var valid_591511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591511 = validateParameter(valid_591511, JString, required = false,
                                 default = nil)
  if valid_591511 != nil:
    section.add "X-Amz-SignedHeaders", valid_591511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591512: Call_DeleteVoiceConnectorGroup_591501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  let valid = call_591512.validator(path, query, header, formData, body)
  let scheme = call_591512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591512.url(scheme.get, call_591512.host, call_591512.base,
                         call_591512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591512, url, valid)

proc call*(call_591513: Call_DeleteVoiceConnectorGroup_591501;
          voiceConnectorGroupId: string): Recallable =
  ## deleteVoiceConnectorGroup
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_591514 = newJObject()
  add(path_591514, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_591513.call(path_591514, nil, nil, nil, nil)

var deleteVoiceConnectorGroup* = Call_DeleteVoiceConnectorGroup_591501(
    name: "deleteVoiceConnectorGroup", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_DeleteVoiceConnectorGroup_591502, base: "/",
    url: url_DeleteVoiceConnectorGroup_591503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_591529 = ref object of OpenApiRestCall_590364
proc url_PutVoiceConnectorOrigination_591531(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorOrigination_591530(path: JsonNode; query: JsonNode;
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
  var valid_591532 = path.getOrDefault("voiceConnectorId")
  valid_591532 = validateParameter(valid_591532, JString, required = true,
                                 default = nil)
  if valid_591532 != nil:
    section.add "voiceConnectorId", valid_591532
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591533 = header.getOrDefault("X-Amz-Signature")
  valid_591533 = validateParameter(valid_591533, JString, required = false,
                                 default = nil)
  if valid_591533 != nil:
    section.add "X-Amz-Signature", valid_591533
  var valid_591534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591534 = validateParameter(valid_591534, JString, required = false,
                                 default = nil)
  if valid_591534 != nil:
    section.add "X-Amz-Content-Sha256", valid_591534
  var valid_591535 = header.getOrDefault("X-Amz-Date")
  valid_591535 = validateParameter(valid_591535, JString, required = false,
                                 default = nil)
  if valid_591535 != nil:
    section.add "X-Amz-Date", valid_591535
  var valid_591536 = header.getOrDefault("X-Amz-Credential")
  valid_591536 = validateParameter(valid_591536, JString, required = false,
                                 default = nil)
  if valid_591536 != nil:
    section.add "X-Amz-Credential", valid_591536
  var valid_591537 = header.getOrDefault("X-Amz-Security-Token")
  valid_591537 = validateParameter(valid_591537, JString, required = false,
                                 default = nil)
  if valid_591537 != nil:
    section.add "X-Amz-Security-Token", valid_591537
  var valid_591538 = header.getOrDefault("X-Amz-Algorithm")
  valid_591538 = validateParameter(valid_591538, JString, required = false,
                                 default = nil)
  if valid_591538 != nil:
    section.add "X-Amz-Algorithm", valid_591538
  var valid_591539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591539 = validateParameter(valid_591539, JString, required = false,
                                 default = nil)
  if valid_591539 != nil:
    section.add "X-Amz-SignedHeaders", valid_591539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591541: Call_PutVoiceConnectorOrigination_591529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591541.validator(path, query, header, formData, body)
  let scheme = call_591541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591541.url(scheme.get, call_591541.host, call_591541.base,
                         call_591541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591541, url, valid)

proc call*(call_591542: Call_PutVoiceConnectorOrigination_591529;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591543 = newJObject()
  var body_591544 = newJObject()
  add(path_591543, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591544 = body
  result = call_591542.call(path_591543, nil, nil, nil, body_591544)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_591529(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_591530, base: "/",
    url: url_PutVoiceConnectorOrigination_591531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_591515 = ref object of OpenApiRestCall_590364
proc url_GetVoiceConnectorOrigination_591517(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorOrigination_591516(path: JsonNode; query: JsonNode;
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
  var valid_591518 = path.getOrDefault("voiceConnectorId")
  valid_591518 = validateParameter(valid_591518, JString, required = true,
                                 default = nil)
  if valid_591518 != nil:
    section.add "voiceConnectorId", valid_591518
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591519 = header.getOrDefault("X-Amz-Signature")
  valid_591519 = validateParameter(valid_591519, JString, required = false,
                                 default = nil)
  if valid_591519 != nil:
    section.add "X-Amz-Signature", valid_591519
  var valid_591520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591520 = validateParameter(valid_591520, JString, required = false,
                                 default = nil)
  if valid_591520 != nil:
    section.add "X-Amz-Content-Sha256", valid_591520
  var valid_591521 = header.getOrDefault("X-Amz-Date")
  valid_591521 = validateParameter(valid_591521, JString, required = false,
                                 default = nil)
  if valid_591521 != nil:
    section.add "X-Amz-Date", valid_591521
  var valid_591522 = header.getOrDefault("X-Amz-Credential")
  valid_591522 = validateParameter(valid_591522, JString, required = false,
                                 default = nil)
  if valid_591522 != nil:
    section.add "X-Amz-Credential", valid_591522
  var valid_591523 = header.getOrDefault("X-Amz-Security-Token")
  valid_591523 = validateParameter(valid_591523, JString, required = false,
                                 default = nil)
  if valid_591523 != nil:
    section.add "X-Amz-Security-Token", valid_591523
  var valid_591524 = header.getOrDefault("X-Amz-Algorithm")
  valid_591524 = validateParameter(valid_591524, JString, required = false,
                                 default = nil)
  if valid_591524 != nil:
    section.add "X-Amz-Algorithm", valid_591524
  var valid_591525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591525 = validateParameter(valid_591525, JString, required = false,
                                 default = nil)
  if valid_591525 != nil:
    section.add "X-Amz-SignedHeaders", valid_591525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591526: Call_GetVoiceConnectorOrigination_591515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591526.validator(path, query, header, formData, body)
  let scheme = call_591526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591526.url(scheme.get, call_591526.host, call_591526.base,
                         call_591526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591526, url, valid)

proc call*(call_591527: Call_GetVoiceConnectorOrigination_591515;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591528 = newJObject()
  add(path_591528, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591527.call(path_591528, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_591515(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_591516, base: "/",
    url: url_GetVoiceConnectorOrigination_591517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_591545 = ref object of OpenApiRestCall_590364
proc url_DeleteVoiceConnectorOrigination_591547(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorOrigination_591546(path: JsonNode;
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
  var valid_591548 = path.getOrDefault("voiceConnectorId")
  valid_591548 = validateParameter(valid_591548, JString, required = true,
                                 default = nil)
  if valid_591548 != nil:
    section.add "voiceConnectorId", valid_591548
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591549 = header.getOrDefault("X-Amz-Signature")
  valid_591549 = validateParameter(valid_591549, JString, required = false,
                                 default = nil)
  if valid_591549 != nil:
    section.add "X-Amz-Signature", valid_591549
  var valid_591550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591550 = validateParameter(valid_591550, JString, required = false,
                                 default = nil)
  if valid_591550 != nil:
    section.add "X-Amz-Content-Sha256", valid_591550
  var valid_591551 = header.getOrDefault("X-Amz-Date")
  valid_591551 = validateParameter(valid_591551, JString, required = false,
                                 default = nil)
  if valid_591551 != nil:
    section.add "X-Amz-Date", valid_591551
  var valid_591552 = header.getOrDefault("X-Amz-Credential")
  valid_591552 = validateParameter(valid_591552, JString, required = false,
                                 default = nil)
  if valid_591552 != nil:
    section.add "X-Amz-Credential", valid_591552
  var valid_591553 = header.getOrDefault("X-Amz-Security-Token")
  valid_591553 = validateParameter(valid_591553, JString, required = false,
                                 default = nil)
  if valid_591553 != nil:
    section.add "X-Amz-Security-Token", valid_591553
  var valid_591554 = header.getOrDefault("X-Amz-Algorithm")
  valid_591554 = validateParameter(valid_591554, JString, required = false,
                                 default = nil)
  if valid_591554 != nil:
    section.add "X-Amz-Algorithm", valid_591554
  var valid_591555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591555 = validateParameter(valid_591555, JString, required = false,
                                 default = nil)
  if valid_591555 != nil:
    section.add "X-Amz-SignedHeaders", valid_591555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591556: Call_DeleteVoiceConnectorOrigination_591545;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591556.validator(path, query, header, formData, body)
  let scheme = call_591556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591556.url(scheme.get, call_591556.host, call_591556.base,
                         call_591556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591556, url, valid)

proc call*(call_591557: Call_DeleteVoiceConnectorOrigination_591545;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591558 = newJObject()
  add(path_591558, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591557.call(path_591558, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_591545(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_591546, base: "/",
    url: url_DeleteVoiceConnectorOrigination_591547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorStreamingConfiguration_591573 = ref object of OpenApiRestCall_590364
proc url_PutVoiceConnectorStreamingConfiguration_591575(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_PutVoiceConnectorStreamingConfiguration_591574(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis, and sets the retention period for the Amazon Kinesis data, in hours.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_591576 = path.getOrDefault("voiceConnectorId")
  valid_591576 = validateParameter(valid_591576, JString, required = true,
                                 default = nil)
  if valid_591576 != nil:
    section.add "voiceConnectorId", valid_591576
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591577 = header.getOrDefault("X-Amz-Signature")
  valid_591577 = validateParameter(valid_591577, JString, required = false,
                                 default = nil)
  if valid_591577 != nil:
    section.add "X-Amz-Signature", valid_591577
  var valid_591578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591578 = validateParameter(valid_591578, JString, required = false,
                                 default = nil)
  if valid_591578 != nil:
    section.add "X-Amz-Content-Sha256", valid_591578
  var valid_591579 = header.getOrDefault("X-Amz-Date")
  valid_591579 = validateParameter(valid_591579, JString, required = false,
                                 default = nil)
  if valid_591579 != nil:
    section.add "X-Amz-Date", valid_591579
  var valid_591580 = header.getOrDefault("X-Amz-Credential")
  valid_591580 = validateParameter(valid_591580, JString, required = false,
                                 default = nil)
  if valid_591580 != nil:
    section.add "X-Amz-Credential", valid_591580
  var valid_591581 = header.getOrDefault("X-Amz-Security-Token")
  valid_591581 = validateParameter(valid_591581, JString, required = false,
                                 default = nil)
  if valid_591581 != nil:
    section.add "X-Amz-Security-Token", valid_591581
  var valid_591582 = header.getOrDefault("X-Amz-Algorithm")
  valid_591582 = validateParameter(valid_591582, JString, required = false,
                                 default = nil)
  if valid_591582 != nil:
    section.add "X-Amz-Algorithm", valid_591582
  var valid_591583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591583 = validateParameter(valid_591583, JString, required = false,
                                 default = nil)
  if valid_591583 != nil:
    section.add "X-Amz-SignedHeaders", valid_591583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591585: Call_PutVoiceConnectorStreamingConfiguration_591573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis, and sets the retention period for the Amazon Kinesis data, in hours.
  ## 
  let valid = call_591585.validator(path, query, header, formData, body)
  let scheme = call_591585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591585.url(scheme.get, call_591585.host, call_591585.base,
                         call_591585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591585, url, valid)

proc call*(call_591586: Call_PutVoiceConnectorStreamingConfiguration_591573;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorStreamingConfiguration
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis, and sets the retention period for the Amazon Kinesis data, in hours.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591587 = newJObject()
  var body_591588 = newJObject()
  add(path_591587, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591588 = body
  result = call_591586.call(path_591587, nil, nil, nil, body_591588)

var putVoiceConnectorStreamingConfiguration* = Call_PutVoiceConnectorStreamingConfiguration_591573(
    name: "putVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_PutVoiceConnectorStreamingConfiguration_591574, base: "/",
    url: url_PutVoiceConnectorStreamingConfiguration_591575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorStreamingConfiguration_591559 = ref object of OpenApiRestCall_590364
proc url_GetVoiceConnectorStreamingConfiguration_591561(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_GetVoiceConnectorStreamingConfiguration_591560(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis, and shows the retention period for the Amazon Kinesis data, in hours.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   voiceConnectorId: JString (required)
  ##                   : The Amazon Chime Voice Connector ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `voiceConnectorId` field"
  var valid_591562 = path.getOrDefault("voiceConnectorId")
  valid_591562 = validateParameter(valid_591562, JString, required = true,
                                 default = nil)
  if valid_591562 != nil:
    section.add "voiceConnectorId", valid_591562
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591563 = header.getOrDefault("X-Amz-Signature")
  valid_591563 = validateParameter(valid_591563, JString, required = false,
                                 default = nil)
  if valid_591563 != nil:
    section.add "X-Amz-Signature", valid_591563
  var valid_591564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591564 = validateParameter(valid_591564, JString, required = false,
                                 default = nil)
  if valid_591564 != nil:
    section.add "X-Amz-Content-Sha256", valid_591564
  var valid_591565 = header.getOrDefault("X-Amz-Date")
  valid_591565 = validateParameter(valid_591565, JString, required = false,
                                 default = nil)
  if valid_591565 != nil:
    section.add "X-Amz-Date", valid_591565
  var valid_591566 = header.getOrDefault("X-Amz-Credential")
  valid_591566 = validateParameter(valid_591566, JString, required = false,
                                 default = nil)
  if valid_591566 != nil:
    section.add "X-Amz-Credential", valid_591566
  var valid_591567 = header.getOrDefault("X-Amz-Security-Token")
  valid_591567 = validateParameter(valid_591567, JString, required = false,
                                 default = nil)
  if valid_591567 != nil:
    section.add "X-Amz-Security-Token", valid_591567
  var valid_591568 = header.getOrDefault("X-Amz-Algorithm")
  valid_591568 = validateParameter(valid_591568, JString, required = false,
                                 default = nil)
  if valid_591568 != nil:
    section.add "X-Amz-Algorithm", valid_591568
  var valid_591569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591569 = validateParameter(valid_591569, JString, required = false,
                                 default = nil)
  if valid_591569 != nil:
    section.add "X-Amz-SignedHeaders", valid_591569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591570: Call_GetVoiceConnectorStreamingConfiguration_591559;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis, and shows the retention period for the Amazon Kinesis data, in hours.
  ## 
  let valid = call_591570.validator(path, query, header, formData, body)
  let scheme = call_591570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591570.url(scheme.get, call_591570.host, call_591570.base,
                         call_591570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591570, url, valid)

proc call*(call_591571: Call_GetVoiceConnectorStreamingConfiguration_591559;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorStreamingConfiguration
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis, and shows the retention period for the Amazon Kinesis data, in hours.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591572 = newJObject()
  add(path_591572, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591571.call(path_591572, nil, nil, nil, nil)

var getVoiceConnectorStreamingConfiguration* = Call_GetVoiceConnectorStreamingConfiguration_591559(
    name: "getVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_GetVoiceConnectorStreamingConfiguration_591560, base: "/",
    url: url_GetVoiceConnectorStreamingConfiguration_591561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorStreamingConfiguration_591589 = ref object of OpenApiRestCall_590364
proc url_DeleteVoiceConnectorStreamingConfiguration_591591(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_DeleteVoiceConnectorStreamingConfiguration_591590(path: JsonNode;
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
  var valid_591592 = path.getOrDefault("voiceConnectorId")
  valid_591592 = validateParameter(valid_591592, JString, required = true,
                                 default = nil)
  if valid_591592 != nil:
    section.add "voiceConnectorId", valid_591592
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591593 = header.getOrDefault("X-Amz-Signature")
  valid_591593 = validateParameter(valid_591593, JString, required = false,
                                 default = nil)
  if valid_591593 != nil:
    section.add "X-Amz-Signature", valid_591593
  var valid_591594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591594 = validateParameter(valid_591594, JString, required = false,
                                 default = nil)
  if valid_591594 != nil:
    section.add "X-Amz-Content-Sha256", valid_591594
  var valid_591595 = header.getOrDefault("X-Amz-Date")
  valid_591595 = validateParameter(valid_591595, JString, required = false,
                                 default = nil)
  if valid_591595 != nil:
    section.add "X-Amz-Date", valid_591595
  var valid_591596 = header.getOrDefault("X-Amz-Credential")
  valid_591596 = validateParameter(valid_591596, JString, required = false,
                                 default = nil)
  if valid_591596 != nil:
    section.add "X-Amz-Credential", valid_591596
  var valid_591597 = header.getOrDefault("X-Amz-Security-Token")
  valid_591597 = validateParameter(valid_591597, JString, required = false,
                                 default = nil)
  if valid_591597 != nil:
    section.add "X-Amz-Security-Token", valid_591597
  var valid_591598 = header.getOrDefault("X-Amz-Algorithm")
  valid_591598 = validateParameter(valid_591598, JString, required = false,
                                 default = nil)
  if valid_591598 != nil:
    section.add "X-Amz-Algorithm", valid_591598
  var valid_591599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591599 = validateParameter(valid_591599, JString, required = false,
                                 default = nil)
  if valid_591599 != nil:
    section.add "X-Amz-SignedHeaders", valid_591599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591600: Call_DeleteVoiceConnectorStreamingConfiguration_591589;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591600.validator(path, query, header, formData, body)
  let scheme = call_591600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591600.url(scheme.get, call_591600.host, call_591600.base,
                         call_591600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591600, url, valid)

proc call*(call_591601: Call_DeleteVoiceConnectorStreamingConfiguration_591589;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorStreamingConfiguration
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591602 = newJObject()
  add(path_591602, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591601.call(path_591602, nil, nil, nil, nil)

var deleteVoiceConnectorStreamingConfiguration* = Call_DeleteVoiceConnectorStreamingConfiguration_591589(
    name: "deleteVoiceConnectorStreamingConfiguration",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_DeleteVoiceConnectorStreamingConfiguration_591590,
    base: "/", url: url_DeleteVoiceConnectorStreamingConfiguration_591591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_591617 = ref object of OpenApiRestCall_590364
proc url_PutVoiceConnectorTermination_591619(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorTermination_591618(path: JsonNode; query: JsonNode;
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
  var valid_591620 = path.getOrDefault("voiceConnectorId")
  valid_591620 = validateParameter(valid_591620, JString, required = true,
                                 default = nil)
  if valid_591620 != nil:
    section.add "voiceConnectorId", valid_591620
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591621 = header.getOrDefault("X-Amz-Signature")
  valid_591621 = validateParameter(valid_591621, JString, required = false,
                                 default = nil)
  if valid_591621 != nil:
    section.add "X-Amz-Signature", valid_591621
  var valid_591622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591622 = validateParameter(valid_591622, JString, required = false,
                                 default = nil)
  if valid_591622 != nil:
    section.add "X-Amz-Content-Sha256", valid_591622
  var valid_591623 = header.getOrDefault("X-Amz-Date")
  valid_591623 = validateParameter(valid_591623, JString, required = false,
                                 default = nil)
  if valid_591623 != nil:
    section.add "X-Amz-Date", valid_591623
  var valid_591624 = header.getOrDefault("X-Amz-Credential")
  valid_591624 = validateParameter(valid_591624, JString, required = false,
                                 default = nil)
  if valid_591624 != nil:
    section.add "X-Amz-Credential", valid_591624
  var valid_591625 = header.getOrDefault("X-Amz-Security-Token")
  valid_591625 = validateParameter(valid_591625, JString, required = false,
                                 default = nil)
  if valid_591625 != nil:
    section.add "X-Amz-Security-Token", valid_591625
  var valid_591626 = header.getOrDefault("X-Amz-Algorithm")
  valid_591626 = validateParameter(valid_591626, JString, required = false,
                                 default = nil)
  if valid_591626 != nil:
    section.add "X-Amz-Algorithm", valid_591626
  var valid_591627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591627 = validateParameter(valid_591627, JString, required = false,
                                 default = nil)
  if valid_591627 != nil:
    section.add "X-Amz-SignedHeaders", valid_591627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591629: Call_PutVoiceConnectorTermination_591617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591629.validator(path, query, header, formData, body)
  let scheme = call_591629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591629.url(scheme.get, call_591629.host, call_591629.base,
                         call_591629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591629, url, valid)

proc call*(call_591630: Call_PutVoiceConnectorTermination_591617;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591631 = newJObject()
  var body_591632 = newJObject()
  add(path_591631, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591632 = body
  result = call_591630.call(path_591631, nil, nil, nil, body_591632)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_591617(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_591618, base: "/",
    url: url_PutVoiceConnectorTermination_591619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_591603 = ref object of OpenApiRestCall_590364
proc url_GetVoiceConnectorTermination_591605(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTermination_591604(path: JsonNode; query: JsonNode;
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
  var valid_591606 = path.getOrDefault("voiceConnectorId")
  valid_591606 = validateParameter(valid_591606, JString, required = true,
                                 default = nil)
  if valid_591606 != nil:
    section.add "voiceConnectorId", valid_591606
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591607 = header.getOrDefault("X-Amz-Signature")
  valid_591607 = validateParameter(valid_591607, JString, required = false,
                                 default = nil)
  if valid_591607 != nil:
    section.add "X-Amz-Signature", valid_591607
  var valid_591608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591608 = validateParameter(valid_591608, JString, required = false,
                                 default = nil)
  if valid_591608 != nil:
    section.add "X-Amz-Content-Sha256", valid_591608
  var valid_591609 = header.getOrDefault("X-Amz-Date")
  valid_591609 = validateParameter(valid_591609, JString, required = false,
                                 default = nil)
  if valid_591609 != nil:
    section.add "X-Amz-Date", valid_591609
  var valid_591610 = header.getOrDefault("X-Amz-Credential")
  valid_591610 = validateParameter(valid_591610, JString, required = false,
                                 default = nil)
  if valid_591610 != nil:
    section.add "X-Amz-Credential", valid_591610
  var valid_591611 = header.getOrDefault("X-Amz-Security-Token")
  valid_591611 = validateParameter(valid_591611, JString, required = false,
                                 default = nil)
  if valid_591611 != nil:
    section.add "X-Amz-Security-Token", valid_591611
  var valid_591612 = header.getOrDefault("X-Amz-Algorithm")
  valid_591612 = validateParameter(valid_591612, JString, required = false,
                                 default = nil)
  if valid_591612 != nil:
    section.add "X-Amz-Algorithm", valid_591612
  var valid_591613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591613 = validateParameter(valid_591613, JString, required = false,
                                 default = nil)
  if valid_591613 != nil:
    section.add "X-Amz-SignedHeaders", valid_591613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591614: Call_GetVoiceConnectorTermination_591603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591614.validator(path, query, header, formData, body)
  let scheme = call_591614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591614.url(scheme.get, call_591614.host, call_591614.base,
                         call_591614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591614, url, valid)

proc call*(call_591615: Call_GetVoiceConnectorTermination_591603;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591616 = newJObject()
  add(path_591616, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591615.call(path_591616, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_591603(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_591604, base: "/",
    url: url_GetVoiceConnectorTermination_591605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_591633 = ref object of OpenApiRestCall_590364
proc url_DeleteVoiceConnectorTermination_591635(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorTermination_591634(path: JsonNode;
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
  var valid_591636 = path.getOrDefault("voiceConnectorId")
  valid_591636 = validateParameter(valid_591636, JString, required = true,
                                 default = nil)
  if valid_591636 != nil:
    section.add "voiceConnectorId", valid_591636
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591637 = header.getOrDefault("X-Amz-Signature")
  valid_591637 = validateParameter(valid_591637, JString, required = false,
                                 default = nil)
  if valid_591637 != nil:
    section.add "X-Amz-Signature", valid_591637
  var valid_591638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591638 = validateParameter(valid_591638, JString, required = false,
                                 default = nil)
  if valid_591638 != nil:
    section.add "X-Amz-Content-Sha256", valid_591638
  var valid_591639 = header.getOrDefault("X-Amz-Date")
  valid_591639 = validateParameter(valid_591639, JString, required = false,
                                 default = nil)
  if valid_591639 != nil:
    section.add "X-Amz-Date", valid_591639
  var valid_591640 = header.getOrDefault("X-Amz-Credential")
  valid_591640 = validateParameter(valid_591640, JString, required = false,
                                 default = nil)
  if valid_591640 != nil:
    section.add "X-Amz-Credential", valid_591640
  var valid_591641 = header.getOrDefault("X-Amz-Security-Token")
  valid_591641 = validateParameter(valid_591641, JString, required = false,
                                 default = nil)
  if valid_591641 != nil:
    section.add "X-Amz-Security-Token", valid_591641
  var valid_591642 = header.getOrDefault("X-Amz-Algorithm")
  valid_591642 = validateParameter(valid_591642, JString, required = false,
                                 default = nil)
  if valid_591642 != nil:
    section.add "X-Amz-Algorithm", valid_591642
  var valid_591643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591643 = validateParameter(valid_591643, JString, required = false,
                                 default = nil)
  if valid_591643 != nil:
    section.add "X-Amz-SignedHeaders", valid_591643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591644: Call_DeleteVoiceConnectorTermination_591633;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591644.validator(path, query, header, formData, body)
  let scheme = call_591644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591644.url(scheme.get, call_591644.host, call_591644.base,
                         call_591644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591644, url, valid)

proc call*(call_591645: Call_DeleteVoiceConnectorTermination_591633;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591646 = newJObject()
  add(path_591646, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591645.call(path_591646, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_591633(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_591634, base: "/",
    url: url_DeleteVoiceConnectorTermination_591635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_591647 = ref object of OpenApiRestCall_590364
proc url_DeleteVoiceConnectorTerminationCredentials_591649(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorTerminationCredentials_591648(path: JsonNode;
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
  var valid_591650 = path.getOrDefault("voiceConnectorId")
  valid_591650 = validateParameter(valid_591650, JString, required = true,
                                 default = nil)
  if valid_591650 != nil:
    section.add "voiceConnectorId", valid_591650
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591651 = query.getOrDefault("operation")
  valid_591651 = validateParameter(valid_591651, JString, required = true,
                                 default = newJString("delete"))
  if valid_591651 != nil:
    section.add "operation", valid_591651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591652 = header.getOrDefault("X-Amz-Signature")
  valid_591652 = validateParameter(valid_591652, JString, required = false,
                                 default = nil)
  if valid_591652 != nil:
    section.add "X-Amz-Signature", valid_591652
  var valid_591653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591653 = validateParameter(valid_591653, JString, required = false,
                                 default = nil)
  if valid_591653 != nil:
    section.add "X-Amz-Content-Sha256", valid_591653
  var valid_591654 = header.getOrDefault("X-Amz-Date")
  valid_591654 = validateParameter(valid_591654, JString, required = false,
                                 default = nil)
  if valid_591654 != nil:
    section.add "X-Amz-Date", valid_591654
  var valid_591655 = header.getOrDefault("X-Amz-Credential")
  valid_591655 = validateParameter(valid_591655, JString, required = false,
                                 default = nil)
  if valid_591655 != nil:
    section.add "X-Amz-Credential", valid_591655
  var valid_591656 = header.getOrDefault("X-Amz-Security-Token")
  valid_591656 = validateParameter(valid_591656, JString, required = false,
                                 default = nil)
  if valid_591656 != nil:
    section.add "X-Amz-Security-Token", valid_591656
  var valid_591657 = header.getOrDefault("X-Amz-Algorithm")
  valid_591657 = validateParameter(valid_591657, JString, required = false,
                                 default = nil)
  if valid_591657 != nil:
    section.add "X-Amz-Algorithm", valid_591657
  var valid_591658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591658 = validateParameter(valid_591658, JString, required = false,
                                 default = nil)
  if valid_591658 != nil:
    section.add "X-Amz-SignedHeaders", valid_591658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591660: Call_DeleteVoiceConnectorTerminationCredentials_591647;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_591660.validator(path, query, header, formData, body)
  let scheme = call_591660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591660.url(scheme.get, call_591660.host, call_591660.base,
                         call_591660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591660, url, valid)

proc call*(call_591661: Call_DeleteVoiceConnectorTerminationCredentials_591647;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591662 = newJObject()
  var query_591663 = newJObject()
  var body_591664 = newJObject()
  add(query_591663, "operation", newJString(operation))
  add(path_591662, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591664 = body
  result = call_591661.call(path_591662, query_591663, nil, nil, body_591664)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_591647(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_591648,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_591649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_591665 = ref object of OpenApiRestCall_590364
proc url_DisassociatePhoneNumberFromUser_591667(protocol: Scheme; host: string;
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

proc validate_DisassociatePhoneNumberFromUser_591666(path: JsonNode;
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
  var valid_591668 = path.getOrDefault("userId")
  valid_591668 = validateParameter(valid_591668, JString, required = true,
                                 default = nil)
  if valid_591668 != nil:
    section.add "userId", valid_591668
  var valid_591669 = path.getOrDefault("accountId")
  valid_591669 = validateParameter(valid_591669, JString, required = true,
                                 default = nil)
  if valid_591669 != nil:
    section.add "accountId", valid_591669
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591670 = query.getOrDefault("operation")
  valid_591670 = validateParameter(valid_591670, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_591670 != nil:
    section.add "operation", valid_591670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591671 = header.getOrDefault("X-Amz-Signature")
  valid_591671 = validateParameter(valid_591671, JString, required = false,
                                 default = nil)
  if valid_591671 != nil:
    section.add "X-Amz-Signature", valid_591671
  var valid_591672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591672 = validateParameter(valid_591672, JString, required = false,
                                 default = nil)
  if valid_591672 != nil:
    section.add "X-Amz-Content-Sha256", valid_591672
  var valid_591673 = header.getOrDefault("X-Amz-Date")
  valid_591673 = validateParameter(valid_591673, JString, required = false,
                                 default = nil)
  if valid_591673 != nil:
    section.add "X-Amz-Date", valid_591673
  var valid_591674 = header.getOrDefault("X-Amz-Credential")
  valid_591674 = validateParameter(valid_591674, JString, required = false,
                                 default = nil)
  if valid_591674 != nil:
    section.add "X-Amz-Credential", valid_591674
  var valid_591675 = header.getOrDefault("X-Amz-Security-Token")
  valid_591675 = validateParameter(valid_591675, JString, required = false,
                                 default = nil)
  if valid_591675 != nil:
    section.add "X-Amz-Security-Token", valid_591675
  var valid_591676 = header.getOrDefault("X-Amz-Algorithm")
  valid_591676 = validateParameter(valid_591676, JString, required = false,
                                 default = nil)
  if valid_591676 != nil:
    section.add "X-Amz-Algorithm", valid_591676
  var valid_591677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591677 = validateParameter(valid_591677, JString, required = false,
                                 default = nil)
  if valid_591677 != nil:
    section.add "X-Amz-SignedHeaders", valid_591677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591678: Call_DisassociatePhoneNumberFromUser_591665;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_591678.validator(path, query, header, formData, body)
  let scheme = call_591678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591678.url(scheme.get, call_591678.host, call_591678.base,
                         call_591678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591678, url, valid)

proc call*(call_591679: Call_DisassociatePhoneNumberFromUser_591665;
          userId: string; accountId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591680 = newJObject()
  var query_591681 = newJObject()
  add(query_591681, "operation", newJString(operation))
  add(path_591680, "userId", newJString(userId))
  add(path_591680, "accountId", newJString(accountId))
  result = call_591679.call(path_591680, query_591681, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_591665(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_591666, base: "/",
    url: url_DisassociatePhoneNumberFromUser_591667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_591682 = ref object of OpenApiRestCall_590364
proc url_DisassociatePhoneNumbersFromVoiceConnector_591684(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnector_591683(path: JsonNode;
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
  var valid_591685 = path.getOrDefault("voiceConnectorId")
  valid_591685 = validateParameter(valid_591685, JString, required = true,
                                 default = nil)
  if valid_591685 != nil:
    section.add "voiceConnectorId", valid_591685
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591686 = query.getOrDefault("operation")
  valid_591686 = validateParameter(valid_591686, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_591686 != nil:
    section.add "operation", valid_591686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591687 = header.getOrDefault("X-Amz-Signature")
  valid_591687 = validateParameter(valid_591687, JString, required = false,
                                 default = nil)
  if valid_591687 != nil:
    section.add "X-Amz-Signature", valid_591687
  var valid_591688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591688 = validateParameter(valid_591688, JString, required = false,
                                 default = nil)
  if valid_591688 != nil:
    section.add "X-Amz-Content-Sha256", valid_591688
  var valid_591689 = header.getOrDefault("X-Amz-Date")
  valid_591689 = validateParameter(valid_591689, JString, required = false,
                                 default = nil)
  if valid_591689 != nil:
    section.add "X-Amz-Date", valid_591689
  var valid_591690 = header.getOrDefault("X-Amz-Credential")
  valid_591690 = validateParameter(valid_591690, JString, required = false,
                                 default = nil)
  if valid_591690 != nil:
    section.add "X-Amz-Credential", valid_591690
  var valid_591691 = header.getOrDefault("X-Amz-Security-Token")
  valid_591691 = validateParameter(valid_591691, JString, required = false,
                                 default = nil)
  if valid_591691 != nil:
    section.add "X-Amz-Security-Token", valid_591691
  var valid_591692 = header.getOrDefault("X-Amz-Algorithm")
  valid_591692 = validateParameter(valid_591692, JString, required = false,
                                 default = nil)
  if valid_591692 != nil:
    section.add "X-Amz-Algorithm", valid_591692
  var valid_591693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591693 = validateParameter(valid_591693, JString, required = false,
                                 default = nil)
  if valid_591693 != nil:
    section.add "X-Amz-SignedHeaders", valid_591693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591695: Call_DisassociatePhoneNumbersFromVoiceConnector_591682;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591695.validator(path, query, header, formData, body)
  let scheme = call_591695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591695.url(scheme.get, call_591695.host, call_591695.base,
                         call_591695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591695, url, valid)

proc call*(call_591696: Call_DisassociatePhoneNumbersFromVoiceConnector_591682;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591697 = newJObject()
  var query_591698 = newJObject()
  var body_591699 = newJObject()
  add(query_591698, "operation", newJString(operation))
  add(path_591697, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591699 = body
  result = call_591696.call(path_591697, query_591698, nil, nil, body_591699)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_591682(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_591683,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_591684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_591700 = ref object of OpenApiRestCall_590364
proc url_DisassociatePhoneNumbersFromVoiceConnectorGroup_591702(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_591701(
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
  var valid_591703 = path.getOrDefault("voiceConnectorGroupId")
  valid_591703 = validateParameter(valid_591703, JString, required = true,
                                 default = nil)
  if valid_591703 != nil:
    section.add "voiceConnectorGroupId", valid_591703
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591704 = query.getOrDefault("operation")
  valid_591704 = validateParameter(valid_591704, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_591704 != nil:
    section.add "operation", valid_591704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591705 = header.getOrDefault("X-Amz-Signature")
  valid_591705 = validateParameter(valid_591705, JString, required = false,
                                 default = nil)
  if valid_591705 != nil:
    section.add "X-Amz-Signature", valid_591705
  var valid_591706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591706 = validateParameter(valid_591706, JString, required = false,
                                 default = nil)
  if valid_591706 != nil:
    section.add "X-Amz-Content-Sha256", valid_591706
  var valid_591707 = header.getOrDefault("X-Amz-Date")
  valid_591707 = validateParameter(valid_591707, JString, required = false,
                                 default = nil)
  if valid_591707 != nil:
    section.add "X-Amz-Date", valid_591707
  var valid_591708 = header.getOrDefault("X-Amz-Credential")
  valid_591708 = validateParameter(valid_591708, JString, required = false,
                                 default = nil)
  if valid_591708 != nil:
    section.add "X-Amz-Credential", valid_591708
  var valid_591709 = header.getOrDefault("X-Amz-Security-Token")
  valid_591709 = validateParameter(valid_591709, JString, required = false,
                                 default = nil)
  if valid_591709 != nil:
    section.add "X-Amz-Security-Token", valid_591709
  var valid_591710 = header.getOrDefault("X-Amz-Algorithm")
  valid_591710 = validateParameter(valid_591710, JString, required = false,
                                 default = nil)
  if valid_591710 != nil:
    section.add "X-Amz-Algorithm", valid_591710
  var valid_591711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591711 = validateParameter(valid_591711, JString, required = false,
                                 default = nil)
  if valid_591711 != nil:
    section.add "X-Amz-SignedHeaders", valid_591711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591713: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_591700;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_591713.validator(path, query, header, formData, body)
  let scheme = call_591713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591713.url(scheme.get, call_591713.host, call_591713.base,
                         call_591713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591713, url, valid)

proc call*(call_591714: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_591700;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnectorGroup
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_591715 = newJObject()
  var query_591716 = newJObject()
  var body_591717 = newJObject()
  add(path_591715, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_591716, "operation", newJString(operation))
  if body != nil:
    body_591717 = body
  result = call_591714.call(path_591715, query_591716, nil, nil, body_591717)

var disassociatePhoneNumbersFromVoiceConnectorGroup* = Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_591700(
    name: "disassociatePhoneNumbersFromVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_591701,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnectorGroup_591702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_591732 = ref object of OpenApiRestCall_590364
proc url_UpdateAccountSettings_591734(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccountSettings_591733(path: JsonNode; query: JsonNode;
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
  var valid_591735 = path.getOrDefault("accountId")
  valid_591735 = validateParameter(valid_591735, JString, required = true,
                                 default = nil)
  if valid_591735 != nil:
    section.add "accountId", valid_591735
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591736 = header.getOrDefault("X-Amz-Signature")
  valid_591736 = validateParameter(valid_591736, JString, required = false,
                                 default = nil)
  if valid_591736 != nil:
    section.add "X-Amz-Signature", valid_591736
  var valid_591737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591737 = validateParameter(valid_591737, JString, required = false,
                                 default = nil)
  if valid_591737 != nil:
    section.add "X-Amz-Content-Sha256", valid_591737
  var valid_591738 = header.getOrDefault("X-Amz-Date")
  valid_591738 = validateParameter(valid_591738, JString, required = false,
                                 default = nil)
  if valid_591738 != nil:
    section.add "X-Amz-Date", valid_591738
  var valid_591739 = header.getOrDefault("X-Amz-Credential")
  valid_591739 = validateParameter(valid_591739, JString, required = false,
                                 default = nil)
  if valid_591739 != nil:
    section.add "X-Amz-Credential", valid_591739
  var valid_591740 = header.getOrDefault("X-Amz-Security-Token")
  valid_591740 = validateParameter(valid_591740, JString, required = false,
                                 default = nil)
  if valid_591740 != nil:
    section.add "X-Amz-Security-Token", valid_591740
  var valid_591741 = header.getOrDefault("X-Amz-Algorithm")
  valid_591741 = validateParameter(valid_591741, JString, required = false,
                                 default = nil)
  if valid_591741 != nil:
    section.add "X-Amz-Algorithm", valid_591741
  var valid_591742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591742 = validateParameter(valid_591742, JString, required = false,
                                 default = nil)
  if valid_591742 != nil:
    section.add "X-Amz-SignedHeaders", valid_591742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591744: Call_UpdateAccountSettings_591732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_591744.validator(path, query, header, formData, body)
  let scheme = call_591744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591744.url(scheme.get, call_591744.host, call_591744.base,
                         call_591744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591744, url, valid)

proc call*(call_591745: Call_UpdateAccountSettings_591732; body: JsonNode;
          accountId: string): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591746 = newJObject()
  var body_591747 = newJObject()
  if body != nil:
    body_591747 = body
  add(path_591746, "accountId", newJString(accountId))
  result = call_591745.call(path_591746, nil, nil, nil, body_591747)

var updateAccountSettings* = Call_UpdateAccountSettings_591732(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_591733, base: "/",
    url: url_UpdateAccountSettings_591734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_591718 = ref object of OpenApiRestCall_590364
proc url_GetAccountSettings_591720(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_591719(path: JsonNode; query: JsonNode;
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
  var valid_591721 = path.getOrDefault("accountId")
  valid_591721 = validateParameter(valid_591721, JString, required = true,
                                 default = nil)
  if valid_591721 != nil:
    section.add "accountId", valid_591721
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591722 = header.getOrDefault("X-Amz-Signature")
  valid_591722 = validateParameter(valid_591722, JString, required = false,
                                 default = nil)
  if valid_591722 != nil:
    section.add "X-Amz-Signature", valid_591722
  var valid_591723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591723 = validateParameter(valid_591723, JString, required = false,
                                 default = nil)
  if valid_591723 != nil:
    section.add "X-Amz-Content-Sha256", valid_591723
  var valid_591724 = header.getOrDefault("X-Amz-Date")
  valid_591724 = validateParameter(valid_591724, JString, required = false,
                                 default = nil)
  if valid_591724 != nil:
    section.add "X-Amz-Date", valid_591724
  var valid_591725 = header.getOrDefault("X-Amz-Credential")
  valid_591725 = validateParameter(valid_591725, JString, required = false,
                                 default = nil)
  if valid_591725 != nil:
    section.add "X-Amz-Credential", valid_591725
  var valid_591726 = header.getOrDefault("X-Amz-Security-Token")
  valid_591726 = validateParameter(valid_591726, JString, required = false,
                                 default = nil)
  if valid_591726 != nil:
    section.add "X-Amz-Security-Token", valid_591726
  var valid_591727 = header.getOrDefault("X-Amz-Algorithm")
  valid_591727 = validateParameter(valid_591727, JString, required = false,
                                 default = nil)
  if valid_591727 != nil:
    section.add "X-Amz-Algorithm", valid_591727
  var valid_591728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591728 = validateParameter(valid_591728, JString, required = false,
                                 default = nil)
  if valid_591728 != nil:
    section.add "X-Amz-SignedHeaders", valid_591728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591729: Call_GetAccountSettings_591718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_591729.validator(path, query, header, formData, body)
  let scheme = call_591729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591729.url(scheme.get, call_591729.host, call_591729.base,
                         call_591729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591729, url, valid)

proc call*(call_591730: Call_GetAccountSettings_591718; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591731 = newJObject()
  add(path_591731, "accountId", newJString(accountId))
  result = call_591730.call(path_591731, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_591718(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_591719, base: "/",
    url: url_GetAccountSettings_591720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_591763 = ref object of OpenApiRestCall_590364
proc url_UpdateBot_591765(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateBot_591764(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591766 = path.getOrDefault("botId")
  valid_591766 = validateParameter(valid_591766, JString, required = true,
                                 default = nil)
  if valid_591766 != nil:
    section.add "botId", valid_591766
  var valid_591767 = path.getOrDefault("accountId")
  valid_591767 = validateParameter(valid_591767, JString, required = true,
                                 default = nil)
  if valid_591767 != nil:
    section.add "accountId", valid_591767
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591768 = header.getOrDefault("X-Amz-Signature")
  valid_591768 = validateParameter(valid_591768, JString, required = false,
                                 default = nil)
  if valid_591768 != nil:
    section.add "X-Amz-Signature", valid_591768
  var valid_591769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591769 = validateParameter(valid_591769, JString, required = false,
                                 default = nil)
  if valid_591769 != nil:
    section.add "X-Amz-Content-Sha256", valid_591769
  var valid_591770 = header.getOrDefault("X-Amz-Date")
  valid_591770 = validateParameter(valid_591770, JString, required = false,
                                 default = nil)
  if valid_591770 != nil:
    section.add "X-Amz-Date", valid_591770
  var valid_591771 = header.getOrDefault("X-Amz-Credential")
  valid_591771 = validateParameter(valid_591771, JString, required = false,
                                 default = nil)
  if valid_591771 != nil:
    section.add "X-Amz-Credential", valid_591771
  var valid_591772 = header.getOrDefault("X-Amz-Security-Token")
  valid_591772 = validateParameter(valid_591772, JString, required = false,
                                 default = nil)
  if valid_591772 != nil:
    section.add "X-Amz-Security-Token", valid_591772
  var valid_591773 = header.getOrDefault("X-Amz-Algorithm")
  valid_591773 = validateParameter(valid_591773, JString, required = false,
                                 default = nil)
  if valid_591773 != nil:
    section.add "X-Amz-Algorithm", valid_591773
  var valid_591774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591774 = validateParameter(valid_591774, JString, required = false,
                                 default = nil)
  if valid_591774 != nil:
    section.add "X-Amz-SignedHeaders", valid_591774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591776: Call_UpdateBot_591763; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_591776.validator(path, query, header, formData, body)
  let scheme = call_591776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591776.url(scheme.get, call_591776.host, call_591776.base,
                         call_591776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591776, url, valid)

proc call*(call_591777: Call_UpdateBot_591763; botId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591778 = newJObject()
  var body_591779 = newJObject()
  add(path_591778, "botId", newJString(botId))
  if body != nil:
    body_591779 = body
  add(path_591778, "accountId", newJString(accountId))
  result = call_591777.call(path_591778, nil, nil, nil, body_591779)

var updateBot* = Call_UpdateBot_591763(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_591764,
                                    base: "/", url: url_UpdateBot_591765,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_591748 = ref object of OpenApiRestCall_590364
proc url_GetBot_591750(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_591749(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591751 = path.getOrDefault("botId")
  valid_591751 = validateParameter(valid_591751, JString, required = true,
                                 default = nil)
  if valid_591751 != nil:
    section.add "botId", valid_591751
  var valid_591752 = path.getOrDefault("accountId")
  valid_591752 = validateParameter(valid_591752, JString, required = true,
                                 default = nil)
  if valid_591752 != nil:
    section.add "accountId", valid_591752
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591753 = header.getOrDefault("X-Amz-Signature")
  valid_591753 = validateParameter(valid_591753, JString, required = false,
                                 default = nil)
  if valid_591753 != nil:
    section.add "X-Amz-Signature", valid_591753
  var valid_591754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591754 = validateParameter(valid_591754, JString, required = false,
                                 default = nil)
  if valid_591754 != nil:
    section.add "X-Amz-Content-Sha256", valid_591754
  var valid_591755 = header.getOrDefault("X-Amz-Date")
  valid_591755 = validateParameter(valid_591755, JString, required = false,
                                 default = nil)
  if valid_591755 != nil:
    section.add "X-Amz-Date", valid_591755
  var valid_591756 = header.getOrDefault("X-Amz-Credential")
  valid_591756 = validateParameter(valid_591756, JString, required = false,
                                 default = nil)
  if valid_591756 != nil:
    section.add "X-Amz-Credential", valid_591756
  var valid_591757 = header.getOrDefault("X-Amz-Security-Token")
  valid_591757 = validateParameter(valid_591757, JString, required = false,
                                 default = nil)
  if valid_591757 != nil:
    section.add "X-Amz-Security-Token", valid_591757
  var valid_591758 = header.getOrDefault("X-Amz-Algorithm")
  valid_591758 = validateParameter(valid_591758, JString, required = false,
                                 default = nil)
  if valid_591758 != nil:
    section.add "X-Amz-Algorithm", valid_591758
  var valid_591759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591759 = validateParameter(valid_591759, JString, required = false,
                                 default = nil)
  if valid_591759 != nil:
    section.add "X-Amz-SignedHeaders", valid_591759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591760: Call_GetBot_591748; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_591760.validator(path, query, header, formData, body)
  let scheme = call_591760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591760.url(scheme.get, call_591760.host, call_591760.base,
                         call_591760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591760, url, valid)

proc call*(call_591761: Call_GetBot_591748; botId: string; accountId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591762 = newJObject()
  add(path_591762, "botId", newJString(botId))
  add(path_591762, "accountId", newJString(accountId))
  result = call_591761.call(path_591762, nil, nil, nil, nil)

var getBot* = Call_GetBot_591748(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_591749, base: "/",
                              url: url_GetBot_591750,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_591792 = ref object of OpenApiRestCall_590364
proc url_UpdateGlobalSettings_591794(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGlobalSettings_591793(path: JsonNode; query: JsonNode;
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
  var valid_591795 = header.getOrDefault("X-Amz-Signature")
  valid_591795 = validateParameter(valid_591795, JString, required = false,
                                 default = nil)
  if valid_591795 != nil:
    section.add "X-Amz-Signature", valid_591795
  var valid_591796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591796 = validateParameter(valid_591796, JString, required = false,
                                 default = nil)
  if valid_591796 != nil:
    section.add "X-Amz-Content-Sha256", valid_591796
  var valid_591797 = header.getOrDefault("X-Amz-Date")
  valid_591797 = validateParameter(valid_591797, JString, required = false,
                                 default = nil)
  if valid_591797 != nil:
    section.add "X-Amz-Date", valid_591797
  var valid_591798 = header.getOrDefault("X-Amz-Credential")
  valid_591798 = validateParameter(valid_591798, JString, required = false,
                                 default = nil)
  if valid_591798 != nil:
    section.add "X-Amz-Credential", valid_591798
  var valid_591799 = header.getOrDefault("X-Amz-Security-Token")
  valid_591799 = validateParameter(valid_591799, JString, required = false,
                                 default = nil)
  if valid_591799 != nil:
    section.add "X-Amz-Security-Token", valid_591799
  var valid_591800 = header.getOrDefault("X-Amz-Algorithm")
  valid_591800 = validateParameter(valid_591800, JString, required = false,
                                 default = nil)
  if valid_591800 != nil:
    section.add "X-Amz-Algorithm", valid_591800
  var valid_591801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591801 = validateParameter(valid_591801, JString, required = false,
                                 default = nil)
  if valid_591801 != nil:
    section.add "X-Amz-SignedHeaders", valid_591801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591803: Call_UpdateGlobalSettings_591792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_591803.validator(path, query, header, formData, body)
  let scheme = call_591803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591803.url(scheme.get, call_591803.host, call_591803.base,
                         call_591803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591803, url, valid)

proc call*(call_591804: Call_UpdateGlobalSettings_591792; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_591805 = newJObject()
  if body != nil:
    body_591805 = body
  result = call_591804.call(nil, nil, nil, nil, body_591805)

var updateGlobalSettings* = Call_UpdateGlobalSettings_591792(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_591793, base: "/",
    url: url_UpdateGlobalSettings_591794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_591780 = ref object of OpenApiRestCall_590364
proc url_GetGlobalSettings_591782(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGlobalSettings_591781(path: JsonNode; query: JsonNode;
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
  var valid_591783 = header.getOrDefault("X-Amz-Signature")
  valid_591783 = validateParameter(valid_591783, JString, required = false,
                                 default = nil)
  if valid_591783 != nil:
    section.add "X-Amz-Signature", valid_591783
  var valid_591784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591784 = validateParameter(valid_591784, JString, required = false,
                                 default = nil)
  if valid_591784 != nil:
    section.add "X-Amz-Content-Sha256", valid_591784
  var valid_591785 = header.getOrDefault("X-Amz-Date")
  valid_591785 = validateParameter(valid_591785, JString, required = false,
                                 default = nil)
  if valid_591785 != nil:
    section.add "X-Amz-Date", valid_591785
  var valid_591786 = header.getOrDefault("X-Amz-Credential")
  valid_591786 = validateParameter(valid_591786, JString, required = false,
                                 default = nil)
  if valid_591786 != nil:
    section.add "X-Amz-Credential", valid_591786
  var valid_591787 = header.getOrDefault("X-Amz-Security-Token")
  valid_591787 = validateParameter(valid_591787, JString, required = false,
                                 default = nil)
  if valid_591787 != nil:
    section.add "X-Amz-Security-Token", valid_591787
  var valid_591788 = header.getOrDefault("X-Amz-Algorithm")
  valid_591788 = validateParameter(valid_591788, JString, required = false,
                                 default = nil)
  if valid_591788 != nil:
    section.add "X-Amz-Algorithm", valid_591788
  var valid_591789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591789 = validateParameter(valid_591789, JString, required = false,
                                 default = nil)
  if valid_591789 != nil:
    section.add "X-Amz-SignedHeaders", valid_591789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591790: Call_GetGlobalSettings_591780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_591790.validator(path, query, header, formData, body)
  let scheme = call_591790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591790.url(scheme.get, call_591790.host, call_591790.base,
                         call_591790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591790, url, valid)

proc call*(call_591791: Call_GetGlobalSettings_591780): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_591791.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_591780(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_591781, base: "/",
    url: url_GetGlobalSettings_591782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_591806 = ref object of OpenApiRestCall_590364
proc url_GetPhoneNumberOrder_591808(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberOrder_591807(path: JsonNode; query: JsonNode;
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
  var valid_591809 = path.getOrDefault("phoneNumberOrderId")
  valid_591809 = validateParameter(valid_591809, JString, required = true,
                                 default = nil)
  if valid_591809 != nil:
    section.add "phoneNumberOrderId", valid_591809
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591810 = header.getOrDefault("X-Amz-Signature")
  valid_591810 = validateParameter(valid_591810, JString, required = false,
                                 default = nil)
  if valid_591810 != nil:
    section.add "X-Amz-Signature", valid_591810
  var valid_591811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591811 = validateParameter(valid_591811, JString, required = false,
                                 default = nil)
  if valid_591811 != nil:
    section.add "X-Amz-Content-Sha256", valid_591811
  var valid_591812 = header.getOrDefault("X-Amz-Date")
  valid_591812 = validateParameter(valid_591812, JString, required = false,
                                 default = nil)
  if valid_591812 != nil:
    section.add "X-Amz-Date", valid_591812
  var valid_591813 = header.getOrDefault("X-Amz-Credential")
  valid_591813 = validateParameter(valid_591813, JString, required = false,
                                 default = nil)
  if valid_591813 != nil:
    section.add "X-Amz-Credential", valid_591813
  var valid_591814 = header.getOrDefault("X-Amz-Security-Token")
  valid_591814 = validateParameter(valid_591814, JString, required = false,
                                 default = nil)
  if valid_591814 != nil:
    section.add "X-Amz-Security-Token", valid_591814
  var valid_591815 = header.getOrDefault("X-Amz-Algorithm")
  valid_591815 = validateParameter(valid_591815, JString, required = false,
                                 default = nil)
  if valid_591815 != nil:
    section.add "X-Amz-Algorithm", valid_591815
  var valid_591816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591816 = validateParameter(valid_591816, JString, required = false,
                                 default = nil)
  if valid_591816 != nil:
    section.add "X-Amz-SignedHeaders", valid_591816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591817: Call_GetPhoneNumberOrder_591806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_591817.validator(path, query, header, formData, body)
  let scheme = call_591817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591817.url(scheme.get, call_591817.host, call_591817.base,
                         call_591817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591817, url, valid)

proc call*(call_591818: Call_GetPhoneNumberOrder_591806; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_591819 = newJObject()
  add(path_591819, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_591818.call(path_591819, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_591806(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_591807, base: "/",
    url: url_GetPhoneNumberOrder_591808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumberSettings_591832 = ref object of OpenApiRestCall_590364
proc url_UpdatePhoneNumberSettings_591834(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePhoneNumberSettings_591833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to be updated.
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
  var valid_591835 = header.getOrDefault("X-Amz-Signature")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "X-Amz-Signature", valid_591835
  var valid_591836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "X-Amz-Content-Sha256", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-Date")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-Date", valid_591837
  var valid_591838 = header.getOrDefault("X-Amz-Credential")
  valid_591838 = validateParameter(valid_591838, JString, required = false,
                                 default = nil)
  if valid_591838 != nil:
    section.add "X-Amz-Credential", valid_591838
  var valid_591839 = header.getOrDefault("X-Amz-Security-Token")
  valid_591839 = validateParameter(valid_591839, JString, required = false,
                                 default = nil)
  if valid_591839 != nil:
    section.add "X-Amz-Security-Token", valid_591839
  var valid_591840 = header.getOrDefault("X-Amz-Algorithm")
  valid_591840 = validateParameter(valid_591840, JString, required = false,
                                 default = nil)
  if valid_591840 != nil:
    section.add "X-Amz-Algorithm", valid_591840
  var valid_591841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591841 = validateParameter(valid_591841, JString, required = false,
                                 default = nil)
  if valid_591841 != nil:
    section.add "X-Amz-SignedHeaders", valid_591841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591843: Call_UpdatePhoneNumberSettings_591832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to be updated.
  ## 
  let valid = call_591843.validator(path, query, header, formData, body)
  let scheme = call_591843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591843.url(scheme.get, call_591843.host, call_591843.base,
                         call_591843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591843, url, valid)

proc call*(call_591844: Call_UpdatePhoneNumberSettings_591832; body: JsonNode): Recallable =
  ## updatePhoneNumberSettings
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to be updated.
  ##   body: JObject (required)
  var body_591845 = newJObject()
  if body != nil:
    body_591845 = body
  result = call_591844.call(nil, nil, nil, nil, body_591845)

var updatePhoneNumberSettings* = Call_UpdatePhoneNumberSettings_591832(
    name: "updatePhoneNumberSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_UpdatePhoneNumberSettings_591833, base: "/",
    url: url_UpdatePhoneNumberSettings_591834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberSettings_591820 = ref object of OpenApiRestCall_590364
proc url_GetPhoneNumberSettings_591822(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPhoneNumberSettings_591821(path: JsonNode; query: JsonNode;
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
  var valid_591823 = header.getOrDefault("X-Amz-Signature")
  valid_591823 = validateParameter(valid_591823, JString, required = false,
                                 default = nil)
  if valid_591823 != nil:
    section.add "X-Amz-Signature", valid_591823
  var valid_591824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591824 = validateParameter(valid_591824, JString, required = false,
                                 default = nil)
  if valid_591824 != nil:
    section.add "X-Amz-Content-Sha256", valid_591824
  var valid_591825 = header.getOrDefault("X-Amz-Date")
  valid_591825 = validateParameter(valid_591825, JString, required = false,
                                 default = nil)
  if valid_591825 != nil:
    section.add "X-Amz-Date", valid_591825
  var valid_591826 = header.getOrDefault("X-Amz-Credential")
  valid_591826 = validateParameter(valid_591826, JString, required = false,
                                 default = nil)
  if valid_591826 != nil:
    section.add "X-Amz-Credential", valid_591826
  var valid_591827 = header.getOrDefault("X-Amz-Security-Token")
  valid_591827 = validateParameter(valid_591827, JString, required = false,
                                 default = nil)
  if valid_591827 != nil:
    section.add "X-Amz-Security-Token", valid_591827
  var valid_591828 = header.getOrDefault("X-Amz-Algorithm")
  valid_591828 = validateParameter(valid_591828, JString, required = false,
                                 default = nil)
  if valid_591828 != nil:
    section.add "X-Amz-Algorithm", valid_591828
  var valid_591829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591829 = validateParameter(valid_591829, JString, required = false,
                                 default = nil)
  if valid_591829 != nil:
    section.add "X-Amz-SignedHeaders", valid_591829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591830: Call_GetPhoneNumberSettings_591820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  let valid = call_591830.validator(path, query, header, formData, body)
  let scheme = call_591830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591830.url(scheme.get, call_591830.host, call_591830.base,
                         call_591830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591830, url, valid)

proc call*(call_591831: Call_GetPhoneNumberSettings_591820): Recallable =
  ## getPhoneNumberSettings
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  result = call_591831.call(nil, nil, nil, nil, nil)

var getPhoneNumberSettings* = Call_GetPhoneNumberSettings_591820(
    name: "getPhoneNumberSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_GetPhoneNumberSettings_591821, base: "/",
    url: url_GetPhoneNumberSettings_591822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_591861 = ref object of OpenApiRestCall_590364
proc url_UpdateUser_591863(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_591862(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591864 = path.getOrDefault("userId")
  valid_591864 = validateParameter(valid_591864, JString, required = true,
                                 default = nil)
  if valid_591864 != nil:
    section.add "userId", valid_591864
  var valid_591865 = path.getOrDefault("accountId")
  valid_591865 = validateParameter(valid_591865, JString, required = true,
                                 default = nil)
  if valid_591865 != nil:
    section.add "accountId", valid_591865
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591866 = header.getOrDefault("X-Amz-Signature")
  valid_591866 = validateParameter(valid_591866, JString, required = false,
                                 default = nil)
  if valid_591866 != nil:
    section.add "X-Amz-Signature", valid_591866
  var valid_591867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591867 = validateParameter(valid_591867, JString, required = false,
                                 default = nil)
  if valid_591867 != nil:
    section.add "X-Amz-Content-Sha256", valid_591867
  var valid_591868 = header.getOrDefault("X-Amz-Date")
  valid_591868 = validateParameter(valid_591868, JString, required = false,
                                 default = nil)
  if valid_591868 != nil:
    section.add "X-Amz-Date", valid_591868
  var valid_591869 = header.getOrDefault("X-Amz-Credential")
  valid_591869 = validateParameter(valid_591869, JString, required = false,
                                 default = nil)
  if valid_591869 != nil:
    section.add "X-Amz-Credential", valid_591869
  var valid_591870 = header.getOrDefault("X-Amz-Security-Token")
  valid_591870 = validateParameter(valid_591870, JString, required = false,
                                 default = nil)
  if valid_591870 != nil:
    section.add "X-Amz-Security-Token", valid_591870
  var valid_591871 = header.getOrDefault("X-Amz-Algorithm")
  valid_591871 = validateParameter(valid_591871, JString, required = false,
                                 default = nil)
  if valid_591871 != nil:
    section.add "X-Amz-Algorithm", valid_591871
  var valid_591872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591872 = validateParameter(valid_591872, JString, required = false,
                                 default = nil)
  if valid_591872 != nil:
    section.add "X-Amz-SignedHeaders", valid_591872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591874: Call_UpdateUser_591861; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_591874.validator(path, query, header, formData, body)
  let scheme = call_591874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591874.url(scheme.get, call_591874.host, call_591874.base,
                         call_591874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591874, url, valid)

proc call*(call_591875: Call_UpdateUser_591861; userId: string; body: JsonNode;
          accountId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591876 = newJObject()
  var body_591877 = newJObject()
  add(path_591876, "userId", newJString(userId))
  if body != nil:
    body_591877 = body
  add(path_591876, "accountId", newJString(accountId))
  result = call_591875.call(path_591876, nil, nil, nil, body_591877)

var updateUser* = Call_UpdateUser_591861(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_591862,
                                      base: "/", url: url_UpdateUser_591863,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_591846 = ref object of OpenApiRestCall_590364
proc url_GetUser_591848(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_591847(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591849 = path.getOrDefault("userId")
  valid_591849 = validateParameter(valid_591849, JString, required = true,
                                 default = nil)
  if valid_591849 != nil:
    section.add "userId", valid_591849
  var valid_591850 = path.getOrDefault("accountId")
  valid_591850 = validateParameter(valid_591850, JString, required = true,
                                 default = nil)
  if valid_591850 != nil:
    section.add "accountId", valid_591850
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591851 = header.getOrDefault("X-Amz-Signature")
  valid_591851 = validateParameter(valid_591851, JString, required = false,
                                 default = nil)
  if valid_591851 != nil:
    section.add "X-Amz-Signature", valid_591851
  var valid_591852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591852 = validateParameter(valid_591852, JString, required = false,
                                 default = nil)
  if valid_591852 != nil:
    section.add "X-Amz-Content-Sha256", valid_591852
  var valid_591853 = header.getOrDefault("X-Amz-Date")
  valid_591853 = validateParameter(valid_591853, JString, required = false,
                                 default = nil)
  if valid_591853 != nil:
    section.add "X-Amz-Date", valid_591853
  var valid_591854 = header.getOrDefault("X-Amz-Credential")
  valid_591854 = validateParameter(valid_591854, JString, required = false,
                                 default = nil)
  if valid_591854 != nil:
    section.add "X-Amz-Credential", valid_591854
  var valid_591855 = header.getOrDefault("X-Amz-Security-Token")
  valid_591855 = validateParameter(valid_591855, JString, required = false,
                                 default = nil)
  if valid_591855 != nil:
    section.add "X-Amz-Security-Token", valid_591855
  var valid_591856 = header.getOrDefault("X-Amz-Algorithm")
  valid_591856 = validateParameter(valid_591856, JString, required = false,
                                 default = nil)
  if valid_591856 != nil:
    section.add "X-Amz-Algorithm", valid_591856
  var valid_591857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591857 = validateParameter(valid_591857, JString, required = false,
                                 default = nil)
  if valid_591857 != nil:
    section.add "X-Amz-SignedHeaders", valid_591857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591858: Call_GetUser_591846; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_591858.validator(path, query, header, formData, body)
  let scheme = call_591858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591858.url(scheme.get, call_591858.host, call_591858.base,
                         call_591858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591858, url, valid)

proc call*(call_591859: Call_GetUser_591846; userId: string; accountId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591860 = newJObject()
  add(path_591860, "userId", newJString(userId))
  add(path_591860, "accountId", newJString(accountId))
  result = call_591859.call(path_591860, nil, nil, nil, nil)

var getUser* = Call_GetUser_591846(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_591847, base: "/",
                                url: url_GetUser_591848,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_591893 = ref object of OpenApiRestCall_590364
proc url_UpdateUserSettings_591895(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserSettings_591894(path: JsonNode; query: JsonNode;
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
  var valid_591896 = path.getOrDefault("userId")
  valid_591896 = validateParameter(valid_591896, JString, required = true,
                                 default = nil)
  if valid_591896 != nil:
    section.add "userId", valid_591896
  var valid_591897 = path.getOrDefault("accountId")
  valid_591897 = validateParameter(valid_591897, JString, required = true,
                                 default = nil)
  if valid_591897 != nil:
    section.add "accountId", valid_591897
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591898 = header.getOrDefault("X-Amz-Signature")
  valid_591898 = validateParameter(valid_591898, JString, required = false,
                                 default = nil)
  if valid_591898 != nil:
    section.add "X-Amz-Signature", valid_591898
  var valid_591899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591899 = validateParameter(valid_591899, JString, required = false,
                                 default = nil)
  if valid_591899 != nil:
    section.add "X-Amz-Content-Sha256", valid_591899
  var valid_591900 = header.getOrDefault("X-Amz-Date")
  valid_591900 = validateParameter(valid_591900, JString, required = false,
                                 default = nil)
  if valid_591900 != nil:
    section.add "X-Amz-Date", valid_591900
  var valid_591901 = header.getOrDefault("X-Amz-Credential")
  valid_591901 = validateParameter(valid_591901, JString, required = false,
                                 default = nil)
  if valid_591901 != nil:
    section.add "X-Amz-Credential", valid_591901
  var valid_591902 = header.getOrDefault("X-Amz-Security-Token")
  valid_591902 = validateParameter(valid_591902, JString, required = false,
                                 default = nil)
  if valid_591902 != nil:
    section.add "X-Amz-Security-Token", valid_591902
  var valid_591903 = header.getOrDefault("X-Amz-Algorithm")
  valid_591903 = validateParameter(valid_591903, JString, required = false,
                                 default = nil)
  if valid_591903 != nil:
    section.add "X-Amz-Algorithm", valid_591903
  var valid_591904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591904 = validateParameter(valid_591904, JString, required = false,
                                 default = nil)
  if valid_591904 != nil:
    section.add "X-Amz-SignedHeaders", valid_591904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591906: Call_UpdateUserSettings_591893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_591906.validator(path, query, header, formData, body)
  let scheme = call_591906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591906.url(scheme.get, call_591906.host, call_591906.base,
                         call_591906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591906, url, valid)

proc call*(call_591907: Call_UpdateUserSettings_591893; userId: string;
          body: JsonNode; accountId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591908 = newJObject()
  var body_591909 = newJObject()
  add(path_591908, "userId", newJString(userId))
  if body != nil:
    body_591909 = body
  add(path_591908, "accountId", newJString(accountId))
  result = call_591907.call(path_591908, nil, nil, nil, body_591909)

var updateUserSettings* = Call_UpdateUserSettings_591893(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_591894, base: "/",
    url: url_UpdateUserSettings_591895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_591878 = ref object of OpenApiRestCall_590364
proc url_GetUserSettings_591880(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserSettings_591879(path: JsonNode; query: JsonNode;
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
  var valid_591881 = path.getOrDefault("userId")
  valid_591881 = validateParameter(valid_591881, JString, required = true,
                                 default = nil)
  if valid_591881 != nil:
    section.add "userId", valid_591881
  var valid_591882 = path.getOrDefault("accountId")
  valid_591882 = validateParameter(valid_591882, JString, required = true,
                                 default = nil)
  if valid_591882 != nil:
    section.add "accountId", valid_591882
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591883 = header.getOrDefault("X-Amz-Signature")
  valid_591883 = validateParameter(valid_591883, JString, required = false,
                                 default = nil)
  if valid_591883 != nil:
    section.add "X-Amz-Signature", valid_591883
  var valid_591884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591884 = validateParameter(valid_591884, JString, required = false,
                                 default = nil)
  if valid_591884 != nil:
    section.add "X-Amz-Content-Sha256", valid_591884
  var valid_591885 = header.getOrDefault("X-Amz-Date")
  valid_591885 = validateParameter(valid_591885, JString, required = false,
                                 default = nil)
  if valid_591885 != nil:
    section.add "X-Amz-Date", valid_591885
  var valid_591886 = header.getOrDefault("X-Amz-Credential")
  valid_591886 = validateParameter(valid_591886, JString, required = false,
                                 default = nil)
  if valid_591886 != nil:
    section.add "X-Amz-Credential", valid_591886
  var valid_591887 = header.getOrDefault("X-Amz-Security-Token")
  valid_591887 = validateParameter(valid_591887, JString, required = false,
                                 default = nil)
  if valid_591887 != nil:
    section.add "X-Amz-Security-Token", valid_591887
  var valid_591888 = header.getOrDefault("X-Amz-Algorithm")
  valid_591888 = validateParameter(valid_591888, JString, required = false,
                                 default = nil)
  if valid_591888 != nil:
    section.add "X-Amz-Algorithm", valid_591888
  var valid_591889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591889 = validateParameter(valid_591889, JString, required = false,
                                 default = nil)
  if valid_591889 != nil:
    section.add "X-Amz-SignedHeaders", valid_591889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591890: Call_GetUserSettings_591878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_591890.validator(path, query, header, formData, body)
  let scheme = call_591890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591890.url(scheme.get, call_591890.host, call_591890.base,
                         call_591890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591890, url, valid)

proc call*(call_591891: Call_GetUserSettings_591878; userId: string;
          accountId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591892 = newJObject()
  add(path_591892, "userId", newJString(userId))
  add(path_591892, "accountId", newJString(accountId))
  result = call_591891.call(path_591892, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_591878(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_591879, base: "/", url: url_GetUserSettings_591880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorLoggingConfiguration_591924 = ref object of OpenApiRestCall_590364
proc url_PutVoiceConnectorLoggingConfiguration_591926(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_PutVoiceConnectorLoggingConfiguration_591925(path: JsonNode;
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
  var valid_591927 = path.getOrDefault("voiceConnectorId")
  valid_591927 = validateParameter(valid_591927, JString, required = true,
                                 default = nil)
  if valid_591927 != nil:
    section.add "voiceConnectorId", valid_591927
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591928 = header.getOrDefault("X-Amz-Signature")
  valid_591928 = validateParameter(valid_591928, JString, required = false,
                                 default = nil)
  if valid_591928 != nil:
    section.add "X-Amz-Signature", valid_591928
  var valid_591929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591929 = validateParameter(valid_591929, JString, required = false,
                                 default = nil)
  if valid_591929 != nil:
    section.add "X-Amz-Content-Sha256", valid_591929
  var valid_591930 = header.getOrDefault("X-Amz-Date")
  valid_591930 = validateParameter(valid_591930, JString, required = false,
                                 default = nil)
  if valid_591930 != nil:
    section.add "X-Amz-Date", valid_591930
  var valid_591931 = header.getOrDefault("X-Amz-Credential")
  valid_591931 = validateParameter(valid_591931, JString, required = false,
                                 default = nil)
  if valid_591931 != nil:
    section.add "X-Amz-Credential", valid_591931
  var valid_591932 = header.getOrDefault("X-Amz-Security-Token")
  valid_591932 = validateParameter(valid_591932, JString, required = false,
                                 default = nil)
  if valid_591932 != nil:
    section.add "X-Amz-Security-Token", valid_591932
  var valid_591933 = header.getOrDefault("X-Amz-Algorithm")
  valid_591933 = validateParameter(valid_591933, JString, required = false,
                                 default = nil)
  if valid_591933 != nil:
    section.add "X-Amz-Algorithm", valid_591933
  var valid_591934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591934 = validateParameter(valid_591934, JString, required = false,
                                 default = nil)
  if valid_591934 != nil:
    section.add "X-Amz-SignedHeaders", valid_591934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591936: Call_PutVoiceConnectorLoggingConfiguration_591924;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_591936.validator(path, query, header, formData, body)
  let scheme = call_591936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591936.url(scheme.get, call_591936.host, call_591936.base,
                         call_591936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591936, url, valid)

proc call*(call_591937: Call_PutVoiceConnectorLoggingConfiguration_591924;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorLoggingConfiguration
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_591938 = newJObject()
  var body_591939 = newJObject()
  add(path_591938, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_591939 = body
  result = call_591937.call(path_591938, nil, nil, nil, body_591939)

var putVoiceConnectorLoggingConfiguration* = Call_PutVoiceConnectorLoggingConfiguration_591924(
    name: "putVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_PutVoiceConnectorLoggingConfiguration_591925, base: "/",
    url: url_PutVoiceConnectorLoggingConfiguration_591926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorLoggingConfiguration_591910 = ref object of OpenApiRestCall_590364
proc url_GetVoiceConnectorLoggingConfiguration_591912(protocol: Scheme;
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
  result.path = base & hydrated.get

proc validate_GetVoiceConnectorLoggingConfiguration_591911(path: JsonNode;
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
  var valid_591913 = path.getOrDefault("voiceConnectorId")
  valid_591913 = validateParameter(valid_591913, JString, required = true,
                                 default = nil)
  if valid_591913 != nil:
    section.add "voiceConnectorId", valid_591913
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591914 = header.getOrDefault("X-Amz-Signature")
  valid_591914 = validateParameter(valid_591914, JString, required = false,
                                 default = nil)
  if valid_591914 != nil:
    section.add "X-Amz-Signature", valid_591914
  var valid_591915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591915 = validateParameter(valid_591915, JString, required = false,
                                 default = nil)
  if valid_591915 != nil:
    section.add "X-Amz-Content-Sha256", valid_591915
  var valid_591916 = header.getOrDefault("X-Amz-Date")
  valid_591916 = validateParameter(valid_591916, JString, required = false,
                                 default = nil)
  if valid_591916 != nil:
    section.add "X-Amz-Date", valid_591916
  var valid_591917 = header.getOrDefault("X-Amz-Credential")
  valid_591917 = validateParameter(valid_591917, JString, required = false,
                                 default = nil)
  if valid_591917 != nil:
    section.add "X-Amz-Credential", valid_591917
  var valid_591918 = header.getOrDefault("X-Amz-Security-Token")
  valid_591918 = validateParameter(valid_591918, JString, required = false,
                                 default = nil)
  if valid_591918 != nil:
    section.add "X-Amz-Security-Token", valid_591918
  var valid_591919 = header.getOrDefault("X-Amz-Algorithm")
  valid_591919 = validateParameter(valid_591919, JString, required = false,
                                 default = nil)
  if valid_591919 != nil:
    section.add "X-Amz-Algorithm", valid_591919
  var valid_591920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591920 = validateParameter(valid_591920, JString, required = false,
                                 default = nil)
  if valid_591920 != nil:
    section.add "X-Amz-SignedHeaders", valid_591920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591921: Call_GetVoiceConnectorLoggingConfiguration_591910;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_591921.validator(path, query, header, formData, body)
  let scheme = call_591921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591921.url(scheme.get, call_591921.host, call_591921.base,
                         call_591921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591921, url, valid)

proc call*(call_591922: Call_GetVoiceConnectorLoggingConfiguration_591910;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorLoggingConfiguration
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591923 = newJObject()
  add(path_591923, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591922.call(path_591923, nil, nil, nil, nil)

var getVoiceConnectorLoggingConfiguration* = Call_GetVoiceConnectorLoggingConfiguration_591910(
    name: "getVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_GetVoiceConnectorLoggingConfiguration_591911, base: "/",
    url: url_GetVoiceConnectorLoggingConfiguration_591912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_591940 = ref object of OpenApiRestCall_590364
proc url_GetVoiceConnectorTerminationHealth_591942(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTerminationHealth_591941(path: JsonNode;
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
  var valid_591943 = path.getOrDefault("voiceConnectorId")
  valid_591943 = validateParameter(valid_591943, JString, required = true,
                                 default = nil)
  if valid_591943 != nil:
    section.add "voiceConnectorId", valid_591943
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591944 = header.getOrDefault("X-Amz-Signature")
  valid_591944 = validateParameter(valid_591944, JString, required = false,
                                 default = nil)
  if valid_591944 != nil:
    section.add "X-Amz-Signature", valid_591944
  var valid_591945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591945 = validateParameter(valid_591945, JString, required = false,
                                 default = nil)
  if valid_591945 != nil:
    section.add "X-Amz-Content-Sha256", valid_591945
  var valid_591946 = header.getOrDefault("X-Amz-Date")
  valid_591946 = validateParameter(valid_591946, JString, required = false,
                                 default = nil)
  if valid_591946 != nil:
    section.add "X-Amz-Date", valid_591946
  var valid_591947 = header.getOrDefault("X-Amz-Credential")
  valid_591947 = validateParameter(valid_591947, JString, required = false,
                                 default = nil)
  if valid_591947 != nil:
    section.add "X-Amz-Credential", valid_591947
  var valid_591948 = header.getOrDefault("X-Amz-Security-Token")
  valid_591948 = validateParameter(valid_591948, JString, required = false,
                                 default = nil)
  if valid_591948 != nil:
    section.add "X-Amz-Security-Token", valid_591948
  var valid_591949 = header.getOrDefault("X-Amz-Algorithm")
  valid_591949 = validateParameter(valid_591949, JString, required = false,
                                 default = nil)
  if valid_591949 != nil:
    section.add "X-Amz-Algorithm", valid_591949
  var valid_591950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591950 = validateParameter(valid_591950, JString, required = false,
                                 default = nil)
  if valid_591950 != nil:
    section.add "X-Amz-SignedHeaders", valid_591950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591951: Call_GetVoiceConnectorTerminationHealth_591940;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_591951.validator(path, query, header, formData, body)
  let scheme = call_591951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591951.url(scheme.get, call_591951.host, call_591951.base,
                         call_591951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591951, url, valid)

proc call*(call_591952: Call_GetVoiceConnectorTerminationHealth_591940;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_591953 = newJObject()
  add(path_591953, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_591952.call(path_591953, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_591940(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_591941, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_591942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_591954 = ref object of OpenApiRestCall_590364
proc url_InviteUsers_591956(protocol: Scheme; host: string; base: string;
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

proc validate_InviteUsers_591955(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591957 = path.getOrDefault("accountId")
  valid_591957 = validateParameter(valid_591957, JString, required = true,
                                 default = nil)
  if valid_591957 != nil:
    section.add "accountId", valid_591957
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_591958 = query.getOrDefault("operation")
  valid_591958 = validateParameter(valid_591958, JString, required = true,
                                 default = newJString("add"))
  if valid_591958 != nil:
    section.add "operation", valid_591958
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591959 = header.getOrDefault("X-Amz-Signature")
  valid_591959 = validateParameter(valid_591959, JString, required = false,
                                 default = nil)
  if valid_591959 != nil:
    section.add "X-Amz-Signature", valid_591959
  var valid_591960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591960 = validateParameter(valid_591960, JString, required = false,
                                 default = nil)
  if valid_591960 != nil:
    section.add "X-Amz-Content-Sha256", valid_591960
  var valid_591961 = header.getOrDefault("X-Amz-Date")
  valid_591961 = validateParameter(valid_591961, JString, required = false,
                                 default = nil)
  if valid_591961 != nil:
    section.add "X-Amz-Date", valid_591961
  var valid_591962 = header.getOrDefault("X-Amz-Credential")
  valid_591962 = validateParameter(valid_591962, JString, required = false,
                                 default = nil)
  if valid_591962 != nil:
    section.add "X-Amz-Credential", valid_591962
  var valid_591963 = header.getOrDefault("X-Amz-Security-Token")
  valid_591963 = validateParameter(valid_591963, JString, required = false,
                                 default = nil)
  if valid_591963 != nil:
    section.add "X-Amz-Security-Token", valid_591963
  var valid_591964 = header.getOrDefault("X-Amz-Algorithm")
  valid_591964 = validateParameter(valid_591964, JString, required = false,
                                 default = nil)
  if valid_591964 != nil:
    section.add "X-Amz-Algorithm", valid_591964
  var valid_591965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591965 = validateParameter(valid_591965, JString, required = false,
                                 default = nil)
  if valid_591965 != nil:
    section.add "X-Amz-SignedHeaders", valid_591965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591967: Call_InviteUsers_591954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_591967.validator(path, query, header, formData, body)
  let scheme = call_591967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591967.url(scheme.get, call_591967.host, call_591967.base,
                         call_591967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591967, url, valid)

proc call*(call_591968: Call_InviteUsers_591954; body: JsonNode; accountId: string;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_591969 = newJObject()
  var query_591970 = newJObject()
  var body_591971 = newJObject()
  add(query_591970, "operation", newJString(operation))
  if body != nil:
    body_591971 = body
  add(path_591969, "accountId", newJString(accountId))
  result = call_591968.call(path_591969, query_591970, nil, nil, body_591971)

var inviteUsers* = Call_InviteUsers_591954(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_591955,
                                        base: "/", url: url_InviteUsers_591956,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_591972 = ref object of OpenApiRestCall_590364
proc url_ListPhoneNumbers_591974(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPhoneNumbers_591973(path: JsonNode; query: JsonNode;
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
  var valid_591975 = query.getOrDefault("MaxResults")
  valid_591975 = validateParameter(valid_591975, JString, required = false,
                                 default = nil)
  if valid_591975 != nil:
    section.add "MaxResults", valid_591975
  var valid_591976 = query.getOrDefault("NextToken")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "NextToken", valid_591976
  var valid_591977 = query.getOrDefault("product-type")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_591977 != nil:
    section.add "product-type", valid_591977
  var valid_591978 = query.getOrDefault("filter-name")
  valid_591978 = validateParameter(valid_591978, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_591978 != nil:
    section.add "filter-name", valid_591978
  var valid_591979 = query.getOrDefault("max-results")
  valid_591979 = validateParameter(valid_591979, JInt, required = false, default = nil)
  if valid_591979 != nil:
    section.add "max-results", valid_591979
  var valid_591980 = query.getOrDefault("status")
  valid_591980 = validateParameter(valid_591980, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_591980 != nil:
    section.add "status", valid_591980
  var valid_591981 = query.getOrDefault("filter-value")
  valid_591981 = validateParameter(valid_591981, JString, required = false,
                                 default = nil)
  if valid_591981 != nil:
    section.add "filter-value", valid_591981
  var valid_591982 = query.getOrDefault("next-token")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "next-token", valid_591982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591983 = header.getOrDefault("X-Amz-Signature")
  valid_591983 = validateParameter(valid_591983, JString, required = false,
                                 default = nil)
  if valid_591983 != nil:
    section.add "X-Amz-Signature", valid_591983
  var valid_591984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591984 = validateParameter(valid_591984, JString, required = false,
                                 default = nil)
  if valid_591984 != nil:
    section.add "X-Amz-Content-Sha256", valid_591984
  var valid_591985 = header.getOrDefault("X-Amz-Date")
  valid_591985 = validateParameter(valid_591985, JString, required = false,
                                 default = nil)
  if valid_591985 != nil:
    section.add "X-Amz-Date", valid_591985
  var valid_591986 = header.getOrDefault("X-Amz-Credential")
  valid_591986 = validateParameter(valid_591986, JString, required = false,
                                 default = nil)
  if valid_591986 != nil:
    section.add "X-Amz-Credential", valid_591986
  var valid_591987 = header.getOrDefault("X-Amz-Security-Token")
  valid_591987 = validateParameter(valid_591987, JString, required = false,
                                 default = nil)
  if valid_591987 != nil:
    section.add "X-Amz-Security-Token", valid_591987
  var valid_591988 = header.getOrDefault("X-Amz-Algorithm")
  valid_591988 = validateParameter(valid_591988, JString, required = false,
                                 default = nil)
  if valid_591988 != nil:
    section.add "X-Amz-Algorithm", valid_591988
  var valid_591989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591989 = validateParameter(valid_591989, JString, required = false,
                                 default = nil)
  if valid_591989 != nil:
    section.add "X-Amz-SignedHeaders", valid_591989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591990: Call_ListPhoneNumbers_591972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  let valid = call_591990.validator(path, query, header, formData, body)
  let scheme = call_591990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591990.url(scheme.get, call_591990.host, call_591990.base,
                         call_591990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591990, url, valid)

proc call*(call_591991: Call_ListPhoneNumbers_591972; MaxResults: string = "";
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
  var query_591992 = newJObject()
  add(query_591992, "MaxResults", newJString(MaxResults))
  add(query_591992, "NextToken", newJString(NextToken))
  add(query_591992, "product-type", newJString(productType))
  add(query_591992, "filter-name", newJString(filterName))
  add(query_591992, "max-results", newJInt(maxResults))
  add(query_591992, "status", newJString(status))
  add(query_591992, "filter-value", newJString(filterValue))
  add(query_591992, "next-token", newJString(nextToken))
  result = call_591991.call(nil, query_591992, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_591972(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_591973, base: "/",
    url: url_ListPhoneNumbers_591974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_591993 = ref object of OpenApiRestCall_590364
proc url_ListVoiceConnectorTerminationCredentials_591995(protocol: Scheme;
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

proc validate_ListVoiceConnectorTerminationCredentials_591994(path: JsonNode;
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
  var valid_591996 = path.getOrDefault("voiceConnectorId")
  valid_591996 = validateParameter(valid_591996, JString, required = true,
                                 default = nil)
  if valid_591996 != nil:
    section.add "voiceConnectorId", valid_591996
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591997 = header.getOrDefault("X-Amz-Signature")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-Signature", valid_591997
  var valid_591998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591998 = validateParameter(valid_591998, JString, required = false,
                                 default = nil)
  if valid_591998 != nil:
    section.add "X-Amz-Content-Sha256", valid_591998
  var valid_591999 = header.getOrDefault("X-Amz-Date")
  valid_591999 = validateParameter(valid_591999, JString, required = false,
                                 default = nil)
  if valid_591999 != nil:
    section.add "X-Amz-Date", valid_591999
  var valid_592000 = header.getOrDefault("X-Amz-Credential")
  valid_592000 = validateParameter(valid_592000, JString, required = false,
                                 default = nil)
  if valid_592000 != nil:
    section.add "X-Amz-Credential", valid_592000
  var valid_592001 = header.getOrDefault("X-Amz-Security-Token")
  valid_592001 = validateParameter(valid_592001, JString, required = false,
                                 default = nil)
  if valid_592001 != nil:
    section.add "X-Amz-Security-Token", valid_592001
  var valid_592002 = header.getOrDefault("X-Amz-Algorithm")
  valid_592002 = validateParameter(valid_592002, JString, required = false,
                                 default = nil)
  if valid_592002 != nil:
    section.add "X-Amz-Algorithm", valid_592002
  var valid_592003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592003 = validateParameter(valid_592003, JString, required = false,
                                 default = nil)
  if valid_592003 != nil:
    section.add "X-Amz-SignedHeaders", valid_592003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592004: Call_ListVoiceConnectorTerminationCredentials_591993;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_592004.validator(path, query, header, formData, body)
  let scheme = call_592004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592004.url(scheme.get, call_592004.host, call_592004.base,
                         call_592004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592004, url, valid)

proc call*(call_592005: Call_ListVoiceConnectorTerminationCredentials_591993;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_592006 = newJObject()
  add(path_592006, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_592005.call(path_592006, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_591993(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_591994,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_591995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_592007 = ref object of OpenApiRestCall_590364
proc url_LogoutUser_592009(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_LogoutUser_592008(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592010 = path.getOrDefault("userId")
  valid_592010 = validateParameter(valid_592010, JString, required = true,
                                 default = nil)
  if valid_592010 != nil:
    section.add "userId", valid_592010
  var valid_592011 = path.getOrDefault("accountId")
  valid_592011 = validateParameter(valid_592011, JString, required = true,
                                 default = nil)
  if valid_592011 != nil:
    section.add "accountId", valid_592011
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_592012 = query.getOrDefault("operation")
  valid_592012 = validateParameter(valid_592012, JString, required = true,
                                 default = newJString("logout"))
  if valid_592012 != nil:
    section.add "operation", valid_592012
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592013 = header.getOrDefault("X-Amz-Signature")
  valid_592013 = validateParameter(valid_592013, JString, required = false,
                                 default = nil)
  if valid_592013 != nil:
    section.add "X-Amz-Signature", valid_592013
  var valid_592014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592014 = validateParameter(valid_592014, JString, required = false,
                                 default = nil)
  if valid_592014 != nil:
    section.add "X-Amz-Content-Sha256", valid_592014
  var valid_592015 = header.getOrDefault("X-Amz-Date")
  valid_592015 = validateParameter(valid_592015, JString, required = false,
                                 default = nil)
  if valid_592015 != nil:
    section.add "X-Amz-Date", valid_592015
  var valid_592016 = header.getOrDefault("X-Amz-Credential")
  valid_592016 = validateParameter(valid_592016, JString, required = false,
                                 default = nil)
  if valid_592016 != nil:
    section.add "X-Amz-Credential", valid_592016
  var valid_592017 = header.getOrDefault("X-Amz-Security-Token")
  valid_592017 = validateParameter(valid_592017, JString, required = false,
                                 default = nil)
  if valid_592017 != nil:
    section.add "X-Amz-Security-Token", valid_592017
  var valid_592018 = header.getOrDefault("X-Amz-Algorithm")
  valid_592018 = validateParameter(valid_592018, JString, required = false,
                                 default = nil)
  if valid_592018 != nil:
    section.add "X-Amz-Algorithm", valid_592018
  var valid_592019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592019 = validateParameter(valid_592019, JString, required = false,
                                 default = nil)
  if valid_592019 != nil:
    section.add "X-Amz-SignedHeaders", valid_592019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592020: Call_LogoutUser_592007; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_592020.validator(path, query, header, formData, body)
  let scheme = call_592020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592020.url(scheme.get, call_592020.host, call_592020.base,
                         call_592020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592020, url, valid)

proc call*(call_592021: Call_LogoutUser_592007; userId: string; accountId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_592022 = newJObject()
  var query_592023 = newJObject()
  add(query_592023, "operation", newJString(operation))
  add(path_592022, "userId", newJString(userId))
  add(path_592022, "accountId", newJString(accountId))
  result = call_592021.call(path_592022, query_592023, nil, nil, nil)

var logoutUser* = Call_LogoutUser_592007(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_592008,
                                      base: "/", url: url_LogoutUser_592009,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_592024 = ref object of OpenApiRestCall_590364
proc url_PutVoiceConnectorTerminationCredentials_592026(protocol: Scheme;
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

proc validate_PutVoiceConnectorTerminationCredentials_592025(path: JsonNode;
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
  var valid_592027 = path.getOrDefault("voiceConnectorId")
  valid_592027 = validateParameter(valid_592027, JString, required = true,
                                 default = nil)
  if valid_592027 != nil:
    section.add "voiceConnectorId", valid_592027
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_592028 = query.getOrDefault("operation")
  valid_592028 = validateParameter(valid_592028, JString, required = true,
                                 default = newJString("put"))
  if valid_592028 != nil:
    section.add "operation", valid_592028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592029 = header.getOrDefault("X-Amz-Signature")
  valid_592029 = validateParameter(valid_592029, JString, required = false,
                                 default = nil)
  if valid_592029 != nil:
    section.add "X-Amz-Signature", valid_592029
  var valid_592030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592030 = validateParameter(valid_592030, JString, required = false,
                                 default = nil)
  if valid_592030 != nil:
    section.add "X-Amz-Content-Sha256", valid_592030
  var valid_592031 = header.getOrDefault("X-Amz-Date")
  valid_592031 = validateParameter(valid_592031, JString, required = false,
                                 default = nil)
  if valid_592031 != nil:
    section.add "X-Amz-Date", valid_592031
  var valid_592032 = header.getOrDefault("X-Amz-Credential")
  valid_592032 = validateParameter(valid_592032, JString, required = false,
                                 default = nil)
  if valid_592032 != nil:
    section.add "X-Amz-Credential", valid_592032
  var valid_592033 = header.getOrDefault("X-Amz-Security-Token")
  valid_592033 = validateParameter(valid_592033, JString, required = false,
                                 default = nil)
  if valid_592033 != nil:
    section.add "X-Amz-Security-Token", valid_592033
  var valid_592034 = header.getOrDefault("X-Amz-Algorithm")
  valid_592034 = validateParameter(valid_592034, JString, required = false,
                                 default = nil)
  if valid_592034 != nil:
    section.add "X-Amz-Algorithm", valid_592034
  var valid_592035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592035 = validateParameter(valid_592035, JString, required = false,
                                 default = nil)
  if valid_592035 != nil:
    section.add "X-Amz-SignedHeaders", valid_592035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592037: Call_PutVoiceConnectorTerminationCredentials_592024;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_592037.validator(path, query, header, formData, body)
  let scheme = call_592037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592037.url(scheme.get, call_592037.host, call_592037.base,
                         call_592037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592037, url, valid)

proc call*(call_592038: Call_PutVoiceConnectorTerminationCredentials_592024;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   operation: string (required)
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_592039 = newJObject()
  var query_592040 = newJObject()
  var body_592041 = newJObject()
  add(query_592040, "operation", newJString(operation))
  add(path_592039, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_592041 = body
  result = call_592038.call(path_592039, query_592040, nil, nil, body_592041)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_592024(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_592025, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_592026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_592042 = ref object of OpenApiRestCall_590364
proc url_RegenerateSecurityToken_592044(protocol: Scheme; host: string; base: string;
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

proc validate_RegenerateSecurityToken_592043(path: JsonNode; query: JsonNode;
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
  var valid_592045 = path.getOrDefault("botId")
  valid_592045 = validateParameter(valid_592045, JString, required = true,
                                 default = nil)
  if valid_592045 != nil:
    section.add "botId", valid_592045
  var valid_592046 = path.getOrDefault("accountId")
  valid_592046 = validateParameter(valid_592046, JString, required = true,
                                 default = nil)
  if valid_592046 != nil:
    section.add "accountId", valid_592046
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_592047 = query.getOrDefault("operation")
  valid_592047 = validateParameter(valid_592047, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_592047 != nil:
    section.add "operation", valid_592047
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592048 = header.getOrDefault("X-Amz-Signature")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "X-Amz-Signature", valid_592048
  var valid_592049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592049 = validateParameter(valid_592049, JString, required = false,
                                 default = nil)
  if valid_592049 != nil:
    section.add "X-Amz-Content-Sha256", valid_592049
  var valid_592050 = header.getOrDefault("X-Amz-Date")
  valid_592050 = validateParameter(valid_592050, JString, required = false,
                                 default = nil)
  if valid_592050 != nil:
    section.add "X-Amz-Date", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-Credential")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-Credential", valid_592051
  var valid_592052 = header.getOrDefault("X-Amz-Security-Token")
  valid_592052 = validateParameter(valid_592052, JString, required = false,
                                 default = nil)
  if valid_592052 != nil:
    section.add "X-Amz-Security-Token", valid_592052
  var valid_592053 = header.getOrDefault("X-Amz-Algorithm")
  valid_592053 = validateParameter(valid_592053, JString, required = false,
                                 default = nil)
  if valid_592053 != nil:
    section.add "X-Amz-Algorithm", valid_592053
  var valid_592054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592054 = validateParameter(valid_592054, JString, required = false,
                                 default = nil)
  if valid_592054 != nil:
    section.add "X-Amz-SignedHeaders", valid_592054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592055: Call_RegenerateSecurityToken_592042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_592055.validator(path, query, header, formData, body)
  let scheme = call_592055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592055.url(scheme.get, call_592055.host, call_592055.base,
                         call_592055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592055, url, valid)

proc call*(call_592056: Call_RegenerateSecurityToken_592042; botId: string;
          accountId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_592057 = newJObject()
  var query_592058 = newJObject()
  add(path_592057, "botId", newJString(botId))
  add(query_592058, "operation", newJString(operation))
  add(path_592057, "accountId", newJString(accountId))
  result = call_592056.call(path_592057, query_592058, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_592042(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_592043, base: "/",
    url: url_RegenerateSecurityToken_592044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_592059 = ref object of OpenApiRestCall_590364
proc url_ResetPersonalPIN_592061(protocol: Scheme; host: string; base: string;
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

proc validate_ResetPersonalPIN_592060(path: JsonNode; query: JsonNode;
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
  var valid_592062 = path.getOrDefault("userId")
  valid_592062 = validateParameter(valid_592062, JString, required = true,
                                 default = nil)
  if valid_592062 != nil:
    section.add "userId", valid_592062
  var valid_592063 = path.getOrDefault("accountId")
  valid_592063 = validateParameter(valid_592063, JString, required = true,
                                 default = nil)
  if valid_592063 != nil:
    section.add "accountId", valid_592063
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_592064 = query.getOrDefault("operation")
  valid_592064 = validateParameter(valid_592064, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_592064 != nil:
    section.add "operation", valid_592064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592065 = header.getOrDefault("X-Amz-Signature")
  valid_592065 = validateParameter(valid_592065, JString, required = false,
                                 default = nil)
  if valid_592065 != nil:
    section.add "X-Amz-Signature", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-Content-Sha256", valid_592066
  var valid_592067 = header.getOrDefault("X-Amz-Date")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = nil)
  if valid_592067 != nil:
    section.add "X-Amz-Date", valid_592067
  var valid_592068 = header.getOrDefault("X-Amz-Credential")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "X-Amz-Credential", valid_592068
  var valid_592069 = header.getOrDefault("X-Amz-Security-Token")
  valid_592069 = validateParameter(valid_592069, JString, required = false,
                                 default = nil)
  if valid_592069 != nil:
    section.add "X-Amz-Security-Token", valid_592069
  var valid_592070 = header.getOrDefault("X-Amz-Algorithm")
  valid_592070 = validateParameter(valid_592070, JString, required = false,
                                 default = nil)
  if valid_592070 != nil:
    section.add "X-Amz-Algorithm", valid_592070
  var valid_592071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592071 = validateParameter(valid_592071, JString, required = false,
                                 default = nil)
  if valid_592071 != nil:
    section.add "X-Amz-SignedHeaders", valid_592071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592072: Call_ResetPersonalPIN_592059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_592072.validator(path, query, header, formData, body)
  let scheme = call_592072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592072.url(scheme.get, call_592072.host, call_592072.base,
                         call_592072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592072, url, valid)

proc call*(call_592073: Call_ResetPersonalPIN_592059; userId: string;
          accountId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_592074 = newJObject()
  var query_592075 = newJObject()
  add(query_592075, "operation", newJString(operation))
  add(path_592074, "userId", newJString(userId))
  add(path_592074, "accountId", newJString(accountId))
  result = call_592073.call(path_592074, query_592075, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_592059(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_592060, base: "/",
    url: url_ResetPersonalPIN_592061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_592076 = ref object of OpenApiRestCall_590364
proc url_RestorePhoneNumber_592078(protocol: Scheme; host: string; base: string;
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

proc validate_RestorePhoneNumber_592077(path: JsonNode; query: JsonNode;
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
  var valid_592079 = path.getOrDefault("phoneNumberId")
  valid_592079 = validateParameter(valid_592079, JString, required = true,
                                 default = nil)
  if valid_592079 != nil:
    section.add "phoneNumberId", valid_592079
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_592080 = query.getOrDefault("operation")
  valid_592080 = validateParameter(valid_592080, JString, required = true,
                                 default = newJString("restore"))
  if valid_592080 != nil:
    section.add "operation", valid_592080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592081 = header.getOrDefault("X-Amz-Signature")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "X-Amz-Signature", valid_592081
  var valid_592082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592082 = validateParameter(valid_592082, JString, required = false,
                                 default = nil)
  if valid_592082 != nil:
    section.add "X-Amz-Content-Sha256", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-Date")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-Date", valid_592083
  var valid_592084 = header.getOrDefault("X-Amz-Credential")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = nil)
  if valid_592084 != nil:
    section.add "X-Amz-Credential", valid_592084
  var valid_592085 = header.getOrDefault("X-Amz-Security-Token")
  valid_592085 = validateParameter(valid_592085, JString, required = false,
                                 default = nil)
  if valid_592085 != nil:
    section.add "X-Amz-Security-Token", valid_592085
  var valid_592086 = header.getOrDefault("X-Amz-Algorithm")
  valid_592086 = validateParameter(valid_592086, JString, required = false,
                                 default = nil)
  if valid_592086 != nil:
    section.add "X-Amz-Algorithm", valid_592086
  var valid_592087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592087 = validateParameter(valid_592087, JString, required = false,
                                 default = nil)
  if valid_592087 != nil:
    section.add "X-Amz-SignedHeaders", valid_592087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592088: Call_RestorePhoneNumber_592076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_592088.validator(path, query, header, formData, body)
  let scheme = call_592088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592088.url(scheme.get, call_592088.host, call_592088.base,
                         call_592088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592088, url, valid)

proc call*(call_592089: Call_RestorePhoneNumber_592076; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_592090 = newJObject()
  var query_592091 = newJObject()
  add(path_592090, "phoneNumberId", newJString(phoneNumberId))
  add(query_592091, "operation", newJString(operation))
  result = call_592089.call(path_592090, query_592091, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_592076(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_592077, base: "/",
    url: url_RestorePhoneNumber_592078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_592092 = ref object of OpenApiRestCall_590364
proc url_SearchAvailablePhoneNumbers_592094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchAvailablePhoneNumbers_592093(path: JsonNode; query: JsonNode;
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
  var valid_592095 = query.getOrDefault("state")
  valid_592095 = validateParameter(valid_592095, JString, required = false,
                                 default = nil)
  if valid_592095 != nil:
    section.add "state", valid_592095
  var valid_592096 = query.getOrDefault("area-code")
  valid_592096 = validateParameter(valid_592096, JString, required = false,
                                 default = nil)
  if valid_592096 != nil:
    section.add "area-code", valid_592096
  var valid_592097 = query.getOrDefault("toll-free-prefix")
  valid_592097 = validateParameter(valid_592097, JString, required = false,
                                 default = nil)
  if valid_592097 != nil:
    section.add "toll-free-prefix", valid_592097
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_592098 = query.getOrDefault("type")
  valid_592098 = validateParameter(valid_592098, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_592098 != nil:
    section.add "type", valid_592098
  var valid_592099 = query.getOrDefault("city")
  valid_592099 = validateParameter(valid_592099, JString, required = false,
                                 default = nil)
  if valid_592099 != nil:
    section.add "city", valid_592099
  var valid_592100 = query.getOrDefault("country")
  valid_592100 = validateParameter(valid_592100, JString, required = false,
                                 default = nil)
  if valid_592100 != nil:
    section.add "country", valid_592100
  var valid_592101 = query.getOrDefault("max-results")
  valid_592101 = validateParameter(valid_592101, JInt, required = false, default = nil)
  if valid_592101 != nil:
    section.add "max-results", valid_592101
  var valid_592102 = query.getOrDefault("next-token")
  valid_592102 = validateParameter(valid_592102, JString, required = false,
                                 default = nil)
  if valid_592102 != nil:
    section.add "next-token", valid_592102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592103 = header.getOrDefault("X-Amz-Signature")
  valid_592103 = validateParameter(valid_592103, JString, required = false,
                                 default = nil)
  if valid_592103 != nil:
    section.add "X-Amz-Signature", valid_592103
  var valid_592104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592104 = validateParameter(valid_592104, JString, required = false,
                                 default = nil)
  if valid_592104 != nil:
    section.add "X-Amz-Content-Sha256", valid_592104
  var valid_592105 = header.getOrDefault("X-Amz-Date")
  valid_592105 = validateParameter(valid_592105, JString, required = false,
                                 default = nil)
  if valid_592105 != nil:
    section.add "X-Amz-Date", valid_592105
  var valid_592106 = header.getOrDefault("X-Amz-Credential")
  valid_592106 = validateParameter(valid_592106, JString, required = false,
                                 default = nil)
  if valid_592106 != nil:
    section.add "X-Amz-Credential", valid_592106
  var valid_592107 = header.getOrDefault("X-Amz-Security-Token")
  valid_592107 = validateParameter(valid_592107, JString, required = false,
                                 default = nil)
  if valid_592107 != nil:
    section.add "X-Amz-Security-Token", valid_592107
  var valid_592108 = header.getOrDefault("X-Amz-Algorithm")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "X-Amz-Algorithm", valid_592108
  var valid_592109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592109 = validateParameter(valid_592109, JString, required = false,
                                 default = nil)
  if valid_592109 != nil:
    section.add "X-Amz-SignedHeaders", valid_592109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592110: Call_SearchAvailablePhoneNumbers_592092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_592110.validator(path, query, header, formData, body)
  let scheme = call_592110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592110.url(scheme.get, call_592110.host, call_592110.base,
                         call_592110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592110, url, valid)

proc call*(call_592111: Call_SearchAvailablePhoneNumbers_592092;
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
  var query_592112 = newJObject()
  add(query_592112, "state", newJString(state))
  add(query_592112, "area-code", newJString(areaCode))
  add(query_592112, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_592112, "type", newJString(`type`))
  add(query_592112, "city", newJString(city))
  add(query_592112, "country", newJString(country))
  add(query_592112, "max-results", newJInt(maxResults))
  add(query_592112, "next-token", newJString(nextToken))
  result = call_592111.call(nil, query_592112, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_592092(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_592093, base: "/",
    url: url_SearchAvailablePhoneNumbers_592094,
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
