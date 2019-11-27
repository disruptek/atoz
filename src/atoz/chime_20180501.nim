
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AssociatePhoneNumberWithUser_599705 = ref object of OpenApiRestCall_599368
proc url_AssociatePhoneNumberWithUser_599707(protocol: Scheme; host: string;
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

proc validate_AssociatePhoneNumberWithUser_599706(path: JsonNode; query: JsonNode;
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
  var valid_599833 = path.getOrDefault("accountId")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "accountId", valid_599833
  var valid_599834 = path.getOrDefault("userId")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = nil)
  if valid_599834 != nil:
    section.add "userId", valid_599834
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_599848 = query.getOrDefault("operation")
  valid_599848 = validateParameter(valid_599848, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_599848 != nil:
    section.add "operation", valid_599848
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
  var valid_599849 = header.getOrDefault("X-Amz-Date")
  valid_599849 = validateParameter(valid_599849, JString, required = false,
                                 default = nil)
  if valid_599849 != nil:
    section.add "X-Amz-Date", valid_599849
  var valid_599850 = header.getOrDefault("X-Amz-Security-Token")
  valid_599850 = validateParameter(valid_599850, JString, required = false,
                                 default = nil)
  if valid_599850 != nil:
    section.add "X-Amz-Security-Token", valid_599850
  var valid_599851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599851 = validateParameter(valid_599851, JString, required = false,
                                 default = nil)
  if valid_599851 != nil:
    section.add "X-Amz-Content-Sha256", valid_599851
  var valid_599852 = header.getOrDefault("X-Amz-Algorithm")
  valid_599852 = validateParameter(valid_599852, JString, required = false,
                                 default = nil)
  if valid_599852 != nil:
    section.add "X-Amz-Algorithm", valid_599852
  var valid_599853 = header.getOrDefault("X-Amz-Signature")
  valid_599853 = validateParameter(valid_599853, JString, required = false,
                                 default = nil)
  if valid_599853 != nil:
    section.add "X-Amz-Signature", valid_599853
  var valid_599854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599854 = validateParameter(valid_599854, JString, required = false,
                                 default = nil)
  if valid_599854 != nil:
    section.add "X-Amz-SignedHeaders", valid_599854
  var valid_599855 = header.getOrDefault("X-Amz-Credential")
  valid_599855 = validateParameter(valid_599855, JString, required = false,
                                 default = nil)
  if valid_599855 != nil:
    section.add "X-Amz-Credential", valid_599855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599879: Call_AssociatePhoneNumberWithUser_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_599879.validator(path, query, header, formData, body)
  let scheme = call_599879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599879.url(scheme.get, call_599879.host, call_599879.base,
                         call_599879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599879, url, valid)

proc call*(call_599950: Call_AssociatePhoneNumberWithUser_599705;
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
  var path_599951 = newJObject()
  var query_599953 = newJObject()
  var body_599954 = newJObject()
  add(path_599951, "accountId", newJString(accountId))
  add(query_599953, "operation", newJString(operation))
  if body != nil:
    body_599954 = body
  add(path_599951, "userId", newJString(userId))
  result = call_599950.call(path_599951, query_599953, nil, nil, body_599954)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_599705(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_599706, base: "/",
    url: url_AssociatePhoneNumberWithUser_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_599993 = ref object of OpenApiRestCall_599368
proc url_AssociatePhoneNumbersWithVoiceConnector_599995(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnector_599994(path: JsonNode;
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
  var valid_599996 = path.getOrDefault("voiceConnectorId")
  valid_599996 = validateParameter(valid_599996, JString, required = true,
                                 default = nil)
  if valid_599996 != nil:
    section.add "voiceConnectorId", valid_599996
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_599997 = query.getOrDefault("operation")
  valid_599997 = validateParameter(valid_599997, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_599997 != nil:
    section.add "operation", valid_599997
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
  var valid_599998 = header.getOrDefault("X-Amz-Date")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Date", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Security-Token")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Security-Token", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Content-Sha256", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Algorithm")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Algorithm", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Signature")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Signature", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-SignedHeaders", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Credential")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Credential", valid_600004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600006: Call_AssociatePhoneNumbersWithVoiceConnector_599993;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600006.validator(path, query, header, formData, body)
  let scheme = call_600006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600006.url(scheme.get, call_600006.host, call_600006.base,
                         call_600006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600006, url, valid)

proc call*(call_600007: Call_AssociatePhoneNumbersWithVoiceConnector_599993;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates phone numbers with the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_600008 = newJObject()
  var query_600009 = newJObject()
  var body_600010 = newJObject()
  add(path_600008, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_600009, "operation", newJString(operation))
  if body != nil:
    body_600010 = body
  result = call_600007.call(path_600008, query_600009, nil, nil, body_600010)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_599993(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_599994, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_599995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnectorGroup_600011 = ref object of OpenApiRestCall_599368
proc url_AssociatePhoneNumbersWithVoiceConnectorGroup_600013(protocol: Scheme;
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

proc validate_AssociatePhoneNumbersWithVoiceConnectorGroup_600012(path: JsonNode;
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
  var valid_600014 = path.getOrDefault("voiceConnectorGroupId")
  valid_600014 = validateParameter(valid_600014, JString, required = true,
                                 default = nil)
  if valid_600014 != nil:
    section.add "voiceConnectorGroupId", valid_600014
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600015 = query.getOrDefault("operation")
  valid_600015 = validateParameter(valid_600015, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_600015 != nil:
    section.add "operation", valid_600015
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
  var valid_600016 = header.getOrDefault("X-Amz-Date")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Date", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Security-Token")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Security-Token", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Content-Sha256", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Algorithm")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Algorithm", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Signature")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Signature", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-SignedHeaders", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Credential")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Credential", valid_600022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600024: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_600011;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_600024.validator(path, query, header, formData, body)
  let scheme = call_600024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600024.url(scheme.get, call_600024.host, call_600024.base,
                         call_600024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600024, url, valid)

proc call*(call_600025: Call_AssociatePhoneNumbersWithVoiceConnectorGroup_600011;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnectorGroup
  ## Associates phone numbers with the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_600026 = newJObject()
  var query_600027 = newJObject()
  var body_600028 = newJObject()
  add(path_600026, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_600027, "operation", newJString(operation))
  if body != nil:
    body_600028 = body
  result = call_600025.call(path_600026, query_600027, nil, nil, body_600028)

var associatePhoneNumbersWithVoiceConnectorGroup* = Call_AssociatePhoneNumbersWithVoiceConnectorGroup_600011(
    name: "associatePhoneNumbersWithVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnectorGroup_600012,
    base: "/", url: url_AssociatePhoneNumbersWithVoiceConnectorGroup_600013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateAttendee_600029 = ref object of OpenApiRestCall_599368
proc url_BatchCreateAttendee_600031(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreateAttendee_600030(path: JsonNode; query: JsonNode;
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
  var valid_600032 = path.getOrDefault("meetingId")
  valid_600032 = validateParameter(valid_600032, JString, required = true,
                                 default = nil)
  if valid_600032 != nil:
    section.add "meetingId", valid_600032
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600033 = query.getOrDefault("operation")
  valid_600033 = validateParameter(valid_600033, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_600033 != nil:
    section.add "operation", valid_600033
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
  var valid_600034 = header.getOrDefault("X-Amz-Date")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Date", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Security-Token")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Security-Token", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Content-Sha256", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Algorithm")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Algorithm", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Signature")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Signature", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-SignedHeaders", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Credential")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Credential", valid_600040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600042: Call_BatchCreateAttendee_600029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ## 
  let valid = call_600042.validator(path, query, header, formData, body)
  let scheme = call_600042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600042.url(scheme.get, call_600042.host, call_600042.base,
                         call_600042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600042, url, valid)

proc call*(call_600043: Call_BatchCreateAttendee_600029; body: JsonNode;
          meetingId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateAttendee
  ## Creates up to 100 new attendees for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>. 
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_600044 = newJObject()
  var query_600045 = newJObject()
  var body_600046 = newJObject()
  add(query_600045, "operation", newJString(operation))
  if body != nil:
    body_600046 = body
  add(path_600044, "meetingId", newJString(meetingId))
  result = call_600043.call(path_600044, query_600045, nil, nil, body_600046)

var batchCreateAttendee* = Call_BatchCreateAttendee_600029(
    name: "batchCreateAttendee", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees#operation=batch-create",
    validator: validate_BatchCreateAttendee_600030, base: "/",
    url: url_BatchCreateAttendee_600031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchCreateRoomMembership_600047 = ref object of OpenApiRestCall_599368
proc url_BatchCreateRoomMembership_600049(protocol: Scheme; host: string;
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

proc validate_BatchCreateRoomMembership_600048(path: JsonNode; query: JsonNode;
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
  var valid_600050 = path.getOrDefault("accountId")
  valid_600050 = validateParameter(valid_600050, JString, required = true,
                                 default = nil)
  if valid_600050 != nil:
    section.add "accountId", valid_600050
  var valid_600051 = path.getOrDefault("roomId")
  valid_600051 = validateParameter(valid_600051, JString, required = true,
                                 default = nil)
  if valid_600051 != nil:
    section.add "roomId", valid_600051
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600052 = query.getOrDefault("operation")
  valid_600052 = validateParameter(valid_600052, JString, required = true,
                                 default = newJString("batch-create"))
  if valid_600052 != nil:
    section.add "operation", valid_600052
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
  var valid_600053 = header.getOrDefault("X-Amz-Date")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Date", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Security-Token")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Security-Token", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_BatchCreateRoomMembership_600047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_BatchCreateRoomMembership_600047; accountId: string;
          body: JsonNode; roomId: string; operation: string = "batch-create"): Recallable =
  ## batchCreateRoomMembership
  ## Adds up to 50 members to a chat room. Members can be either users or bots. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_600063 = newJObject()
  var query_600064 = newJObject()
  var body_600065 = newJObject()
  add(path_600063, "accountId", newJString(accountId))
  add(query_600064, "operation", newJString(operation))
  if body != nil:
    body_600065 = body
  add(path_600063, "roomId", newJString(roomId))
  result = call_600062.call(path_600063, query_600064, nil, nil, body_600065)

var batchCreateRoomMembership* = Call_BatchCreateRoomMembership_600047(
    name: "batchCreateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}/memberships#operation=batch-create",
    validator: validate_BatchCreateRoomMembership_600048, base: "/",
    url: url_BatchCreateRoomMembership_600049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_600066 = ref object of OpenApiRestCall_599368
proc url_BatchDeletePhoneNumber_600068(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeletePhoneNumber_600067(path: JsonNode; query: JsonNode;
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
  var valid_600069 = query.getOrDefault("operation")
  valid_600069 = validateParameter(valid_600069, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_600069 != nil:
    section.add "operation", valid_600069
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
  var valid_600070 = header.getOrDefault("X-Amz-Date")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Date", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Security-Token")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Security-Token", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Content-Sha256", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Algorithm")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Algorithm", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Signature")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Signature", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-SignedHeaders", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Credential")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Credential", valid_600076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600078: Call_BatchDeletePhoneNumber_600066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_600078.validator(path, query, header, formData, body)
  let scheme = call_600078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600078.url(scheme.get, call_600078.host, call_600078.base,
                         call_600078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600078, url, valid)

proc call*(call_600079: Call_BatchDeletePhoneNumber_600066; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_600080 = newJObject()
  var body_600081 = newJObject()
  add(query_600080, "operation", newJString(operation))
  if body != nil:
    body_600081 = body
  result = call_600079.call(nil, query_600080, nil, nil, body_600081)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_600066(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_600067, base: "/",
    url: url_BatchDeletePhoneNumber_600068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_600082 = ref object of OpenApiRestCall_599368
proc url_BatchSuspendUser_600084(protocol: Scheme; host: string; base: string;
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

proc validate_BatchSuspendUser_600083(path: JsonNode; query: JsonNode;
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
  var valid_600085 = path.getOrDefault("accountId")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = nil)
  if valid_600085 != nil:
    section.add "accountId", valid_600085
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600086 = query.getOrDefault("operation")
  valid_600086 = validateParameter(valid_600086, JString, required = true,
                                 default = newJString("suspend"))
  if valid_600086 != nil:
    section.add "operation", valid_600086
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
  var valid_600087 = header.getOrDefault("X-Amz-Date")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Date", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Security-Token")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Security-Token", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Content-Sha256", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Algorithm")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Algorithm", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Signature")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Signature", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-SignedHeaders", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Credential")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Credential", valid_600093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_BatchSuspendUser_600082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_BatchSuspendUser_600082; accountId: string;
          body: JsonNode; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_600097 = newJObject()
  var query_600098 = newJObject()
  var body_600099 = newJObject()
  add(path_600097, "accountId", newJString(accountId))
  add(query_600098, "operation", newJString(operation))
  if body != nil:
    body_600099 = body
  result = call_600096.call(path_600097, query_600098, nil, nil, body_600099)

var batchSuspendUser* = Call_BatchSuspendUser_600082(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_600083, base: "/",
    url: url_BatchSuspendUser_600084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_600100 = ref object of OpenApiRestCall_599368
proc url_BatchUnsuspendUser_600102(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUnsuspendUser_600101(path: JsonNode; query: JsonNode;
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
  var valid_600103 = path.getOrDefault("accountId")
  valid_600103 = validateParameter(valid_600103, JString, required = true,
                                 default = nil)
  if valid_600103 != nil:
    section.add "accountId", valid_600103
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600104 = query.getOrDefault("operation")
  valid_600104 = validateParameter(valid_600104, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_600104 != nil:
    section.add "operation", valid_600104
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
  var valid_600105 = header.getOrDefault("X-Amz-Date")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Date", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Security-Token")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Security-Token", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Content-Sha256", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Algorithm")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Algorithm", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Signature")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Signature", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-SignedHeaders", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Credential")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Credential", valid_600111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600113: Call_BatchUnsuspendUser_600100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_600113.validator(path, query, header, formData, body)
  let scheme = call_600113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600113.url(scheme.get, call_600113.host, call_600113.base,
                         call_600113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600113, url, valid)

proc call*(call_600114: Call_BatchUnsuspendUser_600100; accountId: string;
          body: JsonNode; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_600115 = newJObject()
  var query_600116 = newJObject()
  var body_600117 = newJObject()
  add(path_600115, "accountId", newJString(accountId))
  add(query_600116, "operation", newJString(operation))
  if body != nil:
    body_600117 = body
  result = call_600114.call(path_600115, query_600116, nil, nil, body_600117)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_600100(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_600101, base: "/",
    url: url_BatchUnsuspendUser_600102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_600118 = ref object of OpenApiRestCall_599368
proc url_BatchUpdatePhoneNumber_600120(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchUpdatePhoneNumber_600119(path: JsonNode; query: JsonNode;
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
  var valid_600121 = query.getOrDefault("operation")
  valid_600121 = validateParameter(valid_600121, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_600121 != nil:
    section.add "operation", valid_600121
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
  var valid_600122 = header.getOrDefault("X-Amz-Date")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Date", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Security-Token")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Security-Token", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Content-Sha256", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Algorithm")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Algorithm", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Signature")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Signature", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-SignedHeaders", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Credential")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Credential", valid_600128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600130: Call_BatchUpdatePhoneNumber_600118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_600130.validator(path, query, header, formData, body)
  let scheme = call_600130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600130.url(scheme.get, call_600130.host, call_600130.base,
                         call_600130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600130, url, valid)

proc call*(call_600131: Call_BatchUpdatePhoneNumber_600118; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## <p>Updates phone number product types or calling names. You can update one attribute at a time for each <code>UpdatePhoneNumberRequestItem</code>. For example, you can update either the product type or the calling name.</p> <p>For product types, choose from Amazon Chime Business Calling and Amazon Chime Voice Connector. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_600132 = newJObject()
  var body_600133 = newJObject()
  add(query_600132, "operation", newJString(operation))
  if body != nil:
    body_600133 = body
  result = call_600131.call(nil, query_600132, nil, nil, body_600133)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_600118(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_600119, base: "/",
    url: url_BatchUpdatePhoneNumber_600120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_600154 = ref object of OpenApiRestCall_599368
proc url_BatchUpdateUser_600156(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateUser_600155(path: JsonNode; query: JsonNode;
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
  var valid_600157 = path.getOrDefault("accountId")
  valid_600157 = validateParameter(valid_600157, JString, required = true,
                                 default = nil)
  if valid_600157 != nil:
    section.add "accountId", valid_600157
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
  var valid_600158 = header.getOrDefault("X-Amz-Date")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Date", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Security-Token")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Security-Token", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_BatchUpdateUser_600154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_BatchUpdateUser_600154; accountId: string;
          body: JsonNode): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_600168 = newJObject()
  var body_600169 = newJObject()
  add(path_600168, "accountId", newJString(accountId))
  if body != nil:
    body_600169 = body
  result = call_600167.call(path_600168, nil, nil, nil, body_600169)

var batchUpdateUser* = Call_BatchUpdateUser_600154(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_600155,
    base: "/", url: url_BatchUpdateUser_600156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_600134 = ref object of OpenApiRestCall_599368
proc url_ListUsers_600136(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_600135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600137 = path.getOrDefault("accountId")
  valid_600137 = validateParameter(valid_600137, JString, required = true,
                                 default = nil)
  if valid_600137 != nil:
    section.add "accountId", valid_600137
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
  var valid_600138 = query.getOrDefault("user-email")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "user-email", valid_600138
  var valid_600139 = query.getOrDefault("NextToken")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "NextToken", valid_600139
  var valid_600140 = query.getOrDefault("max-results")
  valid_600140 = validateParameter(valid_600140, JInt, required = false, default = nil)
  if valid_600140 != nil:
    section.add "max-results", valid_600140
  var valid_600141 = query.getOrDefault("next-token")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "next-token", valid_600141
  var valid_600142 = query.getOrDefault("MaxResults")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "MaxResults", valid_600142
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
  var valid_600143 = header.getOrDefault("X-Amz-Date")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Date", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Security-Token")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Security-Token", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600150: Call_ListUsers_600134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_600150.validator(path, query, header, formData, body)
  let scheme = call_600150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600150.url(scheme.get, call_600150.host, call_600150.base,
                         call_600150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600150, url, valid)

proc call*(call_600151: Call_ListUsers_600134; accountId: string;
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
  var path_600152 = newJObject()
  var query_600153 = newJObject()
  add(path_600152, "accountId", newJString(accountId))
  add(query_600153, "user-email", newJString(userEmail))
  add(query_600153, "NextToken", newJString(NextToken))
  add(query_600153, "max-results", newJInt(maxResults))
  add(query_600153, "next-token", newJString(nextToken))
  add(query_600153, "MaxResults", newJString(MaxResults))
  result = call_600151.call(path_600152, query_600153, nil, nil, nil)

var listUsers* = Call_ListUsers_600134(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_600135,
                                    base: "/", url: url_ListUsers_600136,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_600189 = ref object of OpenApiRestCall_599368
proc url_CreateAccount_600191(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAccount_600190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600192 = header.getOrDefault("X-Amz-Date")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Date", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Security-Token")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Security-Token", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Content-Sha256", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Algorithm")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Algorithm", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Signature")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Signature", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-SignedHeaders", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Credential")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Credential", valid_600198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600200: Call_CreateAccount_600189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_600200.validator(path, query, header, formData, body)
  let scheme = call_600200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600200.url(scheme.get, call_600200.host, call_600200.base,
                         call_600200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600200, url, valid)

proc call*(call_600201: Call_CreateAccount_600189; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_600202 = newJObject()
  if body != nil:
    body_600202 = body
  result = call_600201.call(nil, nil, nil, nil, body_600202)

var createAccount* = Call_CreateAccount_600189(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_600190, base: "/", url: url_CreateAccount_600191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_600170 = ref object of OpenApiRestCall_599368
proc url_ListAccounts_600172(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccounts_600171(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600173 = query.getOrDefault("user-email")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "user-email", valid_600173
  var valid_600174 = query.getOrDefault("NextToken")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "NextToken", valid_600174
  var valid_600175 = query.getOrDefault("name")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "name", valid_600175
  var valid_600176 = query.getOrDefault("max-results")
  valid_600176 = validateParameter(valid_600176, JInt, required = false, default = nil)
  if valid_600176 != nil:
    section.add "max-results", valid_600176
  var valid_600177 = query.getOrDefault("next-token")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "next-token", valid_600177
  var valid_600178 = query.getOrDefault("MaxResults")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "MaxResults", valid_600178
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
  var valid_600179 = header.getOrDefault("X-Amz-Date")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Date", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Security-Token")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Security-Token", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Content-Sha256", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Algorithm")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Algorithm", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Signature")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Signature", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-SignedHeaders", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Credential")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Credential", valid_600185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600186: Call_ListAccounts_600170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_600186.validator(path, query, header, formData, body)
  let scheme = call_600186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600186.url(scheme.get, call_600186.host, call_600186.base,
                         call_600186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600186, url, valid)

proc call*(call_600187: Call_ListAccounts_600170; userEmail: string = "";
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
  var query_600188 = newJObject()
  add(query_600188, "user-email", newJString(userEmail))
  add(query_600188, "NextToken", newJString(NextToken))
  add(query_600188, "name", newJString(name))
  add(query_600188, "max-results", newJInt(maxResults))
  add(query_600188, "next-token", newJString(nextToken))
  add(query_600188, "MaxResults", newJString(MaxResults))
  result = call_600187.call(nil, query_600188, nil, nil, nil)

var listAccounts* = Call_ListAccounts_600170(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_600171, base: "/", url: url_ListAccounts_600172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAttendee_600222 = ref object of OpenApiRestCall_599368
proc url_CreateAttendee_600224(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAttendee_600223(path: JsonNode; query: JsonNode;
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
  var valid_600225 = path.getOrDefault("meetingId")
  valid_600225 = validateParameter(valid_600225, JString, required = true,
                                 default = nil)
  if valid_600225 != nil:
    section.add "meetingId", valid_600225
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
  var valid_600226 = header.getOrDefault("X-Amz-Date")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Date", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Security-Token")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Security-Token", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Content-Sha256", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Algorithm")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Algorithm", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Signature")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Signature", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-SignedHeaders", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Credential")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Credential", valid_600232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600234: Call_CreateAttendee_600222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600234.validator(path, query, header, formData, body)
  let scheme = call_600234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600234.url(scheme.get, call_600234.host, call_600234.base,
                         call_600234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600234, url, valid)

proc call*(call_600235: Call_CreateAttendee_600222; body: JsonNode; meetingId: string): Recallable =
  ## createAttendee
  ## Creates a new attendee for an active Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_600236 = newJObject()
  var body_600237 = newJObject()
  if body != nil:
    body_600237 = body
  add(path_600236, "meetingId", newJString(meetingId))
  result = call_600235.call(path_600236, nil, nil, nil, body_600237)

var createAttendee* = Call_CreateAttendee_600222(name: "createAttendee",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_CreateAttendee_600223,
    base: "/", url: url_CreateAttendee_600224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttendees_600203 = ref object of OpenApiRestCall_599368
proc url_ListAttendees_600205(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttendees_600204(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600206 = path.getOrDefault("meetingId")
  valid_600206 = validateParameter(valid_600206, JString, required = true,
                                 default = nil)
  if valid_600206 != nil:
    section.add "meetingId", valid_600206
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
  var valid_600207 = query.getOrDefault("NextToken")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "NextToken", valid_600207
  var valid_600208 = query.getOrDefault("max-results")
  valid_600208 = validateParameter(valid_600208, JInt, required = false, default = nil)
  if valid_600208 != nil:
    section.add "max-results", valid_600208
  var valid_600209 = query.getOrDefault("next-token")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "next-token", valid_600209
  var valid_600210 = query.getOrDefault("MaxResults")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "MaxResults", valid_600210
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
  var valid_600211 = header.getOrDefault("X-Amz-Date")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Date", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Security-Token")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Security-Token", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Content-Sha256", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Algorithm")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Algorithm", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Signature")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Signature", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-SignedHeaders", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Credential")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Credential", valid_600217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600218: Call_ListAttendees_600203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attendees for the specified Amazon Chime SDK meeting. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600218.validator(path, query, header, formData, body)
  let scheme = call_600218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600218.url(scheme.get, call_600218.host, call_600218.base,
                         call_600218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600218, url, valid)

proc call*(call_600219: Call_ListAttendees_600203; meetingId: string;
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
  var path_600220 = newJObject()
  var query_600221 = newJObject()
  add(query_600221, "NextToken", newJString(NextToken))
  add(query_600221, "max-results", newJInt(maxResults))
  add(query_600221, "next-token", newJString(nextToken))
  add(path_600220, "meetingId", newJString(meetingId))
  add(query_600221, "MaxResults", newJString(MaxResults))
  result = call_600219.call(path_600220, query_600221, nil, nil, nil)

var listAttendees* = Call_ListAttendees_600203(name: "listAttendees",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees", validator: validate_ListAttendees_600204,
    base: "/", url: url_ListAttendees_600205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_600257 = ref object of OpenApiRestCall_599368
proc url_CreateBot_600259(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateBot_600258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600260 = path.getOrDefault("accountId")
  valid_600260 = validateParameter(valid_600260, JString, required = true,
                                 default = nil)
  if valid_600260 != nil:
    section.add "accountId", valid_600260
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
  var valid_600261 = header.getOrDefault("X-Amz-Date")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Date", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Security-Token")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Security-Token", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Content-Sha256", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Algorithm")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Algorithm", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Signature")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Signature", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-SignedHeaders", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Credential")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Credential", valid_600267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_CreateBot_600257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_CreateBot_600257; accountId: string; body: JsonNode): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_600271 = newJObject()
  var body_600272 = newJObject()
  add(path_600271, "accountId", newJString(accountId))
  if body != nil:
    body_600272 = body
  result = call_600270.call(path_600271, nil, nil, nil, body_600272)

var createBot* = Call_CreateBot_600257(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_600258,
                                    base: "/", url: url_CreateBot_600259,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_600238 = ref object of OpenApiRestCall_599368
proc url_ListBots_600240(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListBots_600239(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600241 = path.getOrDefault("accountId")
  valid_600241 = validateParameter(valid_600241, JString, required = true,
                                 default = nil)
  if valid_600241 != nil:
    section.add "accountId", valid_600241
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
  var valid_600242 = query.getOrDefault("NextToken")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "NextToken", valid_600242
  var valid_600243 = query.getOrDefault("max-results")
  valid_600243 = validateParameter(valid_600243, JInt, required = false, default = nil)
  if valid_600243 != nil:
    section.add "max-results", valid_600243
  var valid_600244 = query.getOrDefault("next-token")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "next-token", valid_600244
  var valid_600245 = query.getOrDefault("MaxResults")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "MaxResults", valid_600245
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
  var valid_600246 = header.getOrDefault("X-Amz-Date")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Date", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Security-Token")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Security-Token", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Content-Sha256", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Algorithm")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Algorithm", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Signature")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Signature", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-SignedHeaders", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Credential")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Credential", valid_600252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600253: Call_ListBots_600238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_600253.validator(path, query, header, formData, body)
  let scheme = call_600253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600253.url(scheme.get, call_600253.host, call_600253.base,
                         call_600253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600253, url, valid)

proc call*(call_600254: Call_ListBots_600238; accountId: string;
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
  var path_600255 = newJObject()
  var query_600256 = newJObject()
  add(path_600255, "accountId", newJString(accountId))
  add(query_600256, "NextToken", newJString(NextToken))
  add(query_600256, "max-results", newJInt(maxResults))
  add(query_600256, "next-token", newJString(nextToken))
  add(query_600256, "MaxResults", newJString(MaxResults))
  result = call_600254.call(path_600255, query_600256, nil, nil, nil)

var listBots* = Call_ListBots_600238(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_600239, base: "/",
                                  url: url_ListBots_600240,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMeeting_600290 = ref object of OpenApiRestCall_599368
proc url_CreateMeeting_600292(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMeeting_600291(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600293 = header.getOrDefault("X-Amz-Date")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Date", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Security-Token")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Security-Token", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_CreateMeeting_600290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_CreateMeeting_600290; body: JsonNode): Recallable =
  ## createMeeting
  ## Creates a new Amazon Chime SDK meeting in the specified media Region with no initial attendees. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   body: JObject (required)
  var body_600303 = newJObject()
  if body != nil:
    body_600303 = body
  result = call_600302.call(nil, nil, nil, nil, body_600303)

var createMeeting* = Call_CreateMeeting_600290(name: "createMeeting",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_CreateMeeting_600291, base: "/", url: url_CreateMeeting_600292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeetings_600273 = ref object of OpenApiRestCall_599368
proc url_ListMeetings_600275(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeetings_600274(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600276 = query.getOrDefault("NextToken")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "NextToken", valid_600276
  var valid_600277 = query.getOrDefault("max-results")
  valid_600277 = validateParameter(valid_600277, JInt, required = false, default = nil)
  if valid_600277 != nil:
    section.add "max-results", valid_600277
  var valid_600278 = query.getOrDefault("next-token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "next-token", valid_600278
  var valid_600279 = query.getOrDefault("MaxResults")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "MaxResults", valid_600279
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
  var valid_600280 = header.getOrDefault("X-Amz-Date")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Date", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Security-Token")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Security-Token", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Content-Sha256", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Algorithm")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Algorithm", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Signature")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Signature", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-SignedHeaders", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Credential")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Credential", valid_600286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600287: Call_ListMeetings_600273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists up to 100 active Amazon Chime SDK meetings. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600287.validator(path, query, header, formData, body)
  let scheme = call_600287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600287.url(scheme.get, call_600287.host, call_600287.base,
                         call_600287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600287, url, valid)

proc call*(call_600288: Call_ListMeetings_600273; NextToken: string = "";
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
  var query_600289 = newJObject()
  add(query_600289, "NextToken", newJString(NextToken))
  add(query_600289, "max-results", newJInt(maxResults))
  add(query_600289, "next-token", newJString(nextToken))
  add(query_600289, "MaxResults", newJString(MaxResults))
  result = call_600288.call(nil, query_600289, nil, nil, nil)

var listMeetings* = Call_ListMeetings_600273(name: "listMeetings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/meetings",
    validator: validate_ListMeetings_600274, base: "/", url: url_ListMeetings_600275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_600321 = ref object of OpenApiRestCall_599368
proc url_CreatePhoneNumberOrder_600323(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePhoneNumberOrder_600322(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600324 = header.getOrDefault("X-Amz-Date")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Date", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Security-Token")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Security-Token", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Content-Sha256", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Algorithm")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Algorithm", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Signature")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Signature", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-SignedHeaders", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Credential")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Credential", valid_600330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600332: Call_CreatePhoneNumberOrder_600321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_600332.validator(path, query, header, formData, body)
  let scheme = call_600332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600332.url(scheme.get, call_600332.host, call_600332.base,
                         call_600332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600332, url, valid)

proc call*(call_600333: Call_CreatePhoneNumberOrder_600321; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you must use the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_600334 = newJObject()
  if body != nil:
    body_600334 = body
  result = call_600333.call(nil, nil, nil, nil, body_600334)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_600321(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_600322, base: "/",
    url: url_CreatePhoneNumberOrder_600323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_600304 = ref object of OpenApiRestCall_599368
proc url_ListPhoneNumberOrders_600306(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumberOrders_600305(path: JsonNode; query: JsonNode;
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
  var valid_600307 = query.getOrDefault("NextToken")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "NextToken", valid_600307
  var valid_600308 = query.getOrDefault("max-results")
  valid_600308 = validateParameter(valid_600308, JInt, required = false, default = nil)
  if valid_600308 != nil:
    section.add "max-results", valid_600308
  var valid_600309 = query.getOrDefault("next-token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "next-token", valid_600309
  var valid_600310 = query.getOrDefault("MaxResults")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "MaxResults", valid_600310
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
  var valid_600311 = header.getOrDefault("X-Amz-Date")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Date", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Security-Token")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Security-Token", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Content-Sha256", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Algorithm")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Algorithm", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Signature")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Signature", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-SignedHeaders", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Credential")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Credential", valid_600317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600318: Call_ListPhoneNumberOrders_600304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_600318.validator(path, query, header, formData, body)
  let scheme = call_600318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600318.url(scheme.get, call_600318.host, call_600318.base,
                         call_600318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600318, url, valid)

proc call*(call_600319: Call_ListPhoneNumberOrders_600304; NextToken: string = "";
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
  var query_600320 = newJObject()
  add(query_600320, "NextToken", newJString(NextToken))
  add(query_600320, "max-results", newJInt(maxResults))
  add(query_600320, "next-token", newJString(nextToken))
  add(query_600320, "MaxResults", newJString(MaxResults))
  result = call_600319.call(nil, query_600320, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_600304(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_600305, base: "/",
    url: url_ListPhoneNumberOrders_600306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_600355 = ref object of OpenApiRestCall_599368
proc url_CreateRoom_600357(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateRoom_600356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600358 = path.getOrDefault("accountId")
  valid_600358 = validateParameter(valid_600358, JString, required = true,
                                 default = nil)
  if valid_600358 != nil:
    section.add "accountId", valid_600358
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
  var valid_600359 = header.getOrDefault("X-Amz-Date")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Date", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Security-Token")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Security-Token", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Content-Sha256", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Algorithm")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Algorithm", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Signature")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Signature", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-SignedHeaders", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Credential")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Credential", valid_600365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600367: Call_CreateRoom_600355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a chat room for the specified Amazon Chime account.
  ## 
  let valid = call_600367.validator(path, query, header, formData, body)
  let scheme = call_600367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600367.url(scheme.get, call_600367.host, call_600367.base,
                         call_600367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600367, url, valid)

proc call*(call_600368: Call_CreateRoom_600355; accountId: string; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a chat room for the specified Amazon Chime account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_600369 = newJObject()
  var body_600370 = newJObject()
  add(path_600369, "accountId", newJString(accountId))
  if body != nil:
    body_600370 = body
  result = call_600368.call(path_600369, nil, nil, nil, body_600370)

var createRoom* = Call_CreateRoom_600355(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}/rooms",
                                      validator: validate_CreateRoom_600356,
                                      base: "/", url: url_CreateRoom_600357,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRooms_600335 = ref object of OpenApiRestCall_599368
proc url_ListRooms_600337(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListRooms_600336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600338 = path.getOrDefault("accountId")
  valid_600338 = validateParameter(valid_600338, JString, required = true,
                                 default = nil)
  if valid_600338 != nil:
    section.add "accountId", valid_600338
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
  var valid_600339 = query.getOrDefault("NextToken")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "NextToken", valid_600339
  var valid_600340 = query.getOrDefault("member-id")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "member-id", valid_600340
  var valid_600341 = query.getOrDefault("max-results")
  valid_600341 = validateParameter(valid_600341, JInt, required = false, default = nil)
  if valid_600341 != nil:
    section.add "max-results", valid_600341
  var valid_600342 = query.getOrDefault("next-token")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "next-token", valid_600342
  var valid_600343 = query.getOrDefault("MaxResults")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "MaxResults", valid_600343
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
  var valid_600344 = header.getOrDefault("X-Amz-Date")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Date", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Security-Token")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Security-Token", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Content-Sha256", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Algorithm")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Algorithm", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Signature")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Signature", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-SignedHeaders", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Credential")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Credential", valid_600350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600351: Call_ListRooms_600335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the room details for the specified Amazon Chime account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
  ## 
  let valid = call_600351.validator(path, query, header, formData, body)
  let scheme = call_600351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600351.url(scheme.get, call_600351.host, call_600351.base,
                         call_600351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600351, url, valid)

proc call*(call_600352: Call_ListRooms_600335; accountId: string;
          NextToken: string = ""; memberId: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRooms
  ## Lists the room details for the specified Amazon Chime account. Optionally, filter the results by a member ID (user ID or bot ID) to see a list of rooms that the member belongs to.
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
  var path_600353 = newJObject()
  var query_600354 = newJObject()
  add(path_600353, "accountId", newJString(accountId))
  add(query_600354, "NextToken", newJString(NextToken))
  add(query_600354, "member-id", newJString(memberId))
  add(query_600354, "max-results", newJInt(maxResults))
  add(query_600354, "next-token", newJString(nextToken))
  add(query_600354, "MaxResults", newJString(MaxResults))
  result = call_600352.call(path_600353, query_600354, nil, nil, nil)

var listRooms* = Call_ListRooms_600335(name: "listRooms", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/rooms",
                                    validator: validate_ListRooms_600336,
                                    base: "/", url: url_ListRooms_600337,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoomMembership_600391 = ref object of OpenApiRestCall_599368
proc url_CreateRoomMembership_600393(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoomMembership_600392(path: JsonNode; query: JsonNode;
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
  var valid_600394 = path.getOrDefault("accountId")
  valid_600394 = validateParameter(valid_600394, JString, required = true,
                                 default = nil)
  if valid_600394 != nil:
    section.add "accountId", valid_600394
  var valid_600395 = path.getOrDefault("roomId")
  valid_600395 = validateParameter(valid_600395, JString, required = true,
                                 default = nil)
  if valid_600395 != nil:
    section.add "roomId", valid_600395
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
  var valid_600396 = header.getOrDefault("X-Amz-Date")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Date", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Security-Token")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Security-Token", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Content-Sha256", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Algorithm")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Algorithm", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Signature")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Signature", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-SignedHeaders", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Credential")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Credential", valid_600402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600404: Call_CreateRoomMembership_600391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ## 
  let valid = call_600404.validator(path, query, header, formData, body)
  let scheme = call_600404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600404.url(scheme.get, call_600404.host, call_600404.base,
                         call_600404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600404, url, valid)

proc call*(call_600405: Call_CreateRoomMembership_600391; accountId: string;
          body: JsonNode; roomId: string): Recallable =
  ## createRoomMembership
  ## Adds a member to a chat room. A member can be either a user or a bot. The member role designates whether the member is a chat room administrator or a general chat room member.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_600406 = newJObject()
  var body_600407 = newJObject()
  add(path_600406, "accountId", newJString(accountId))
  if body != nil:
    body_600407 = body
  add(path_600406, "roomId", newJString(roomId))
  result = call_600405.call(path_600406, nil, nil, nil, body_600407)

var createRoomMembership* = Call_CreateRoomMembership_600391(
    name: "createRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_CreateRoomMembership_600392, base: "/",
    url: url_CreateRoomMembership_600393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoomMemberships_600371 = ref object of OpenApiRestCall_599368
proc url_ListRoomMemberships_600373(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoomMemberships_600372(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the membership details for the specified room, such as member IDs, member email addresses, and member names.
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
  var valid_600374 = path.getOrDefault("accountId")
  valid_600374 = validateParameter(valid_600374, JString, required = true,
                                 default = nil)
  if valid_600374 != nil:
    section.add "accountId", valid_600374
  var valid_600375 = path.getOrDefault("roomId")
  valid_600375 = validateParameter(valid_600375, JString, required = true,
                                 default = nil)
  if valid_600375 != nil:
    section.add "roomId", valid_600375
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
  var valid_600376 = query.getOrDefault("NextToken")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "NextToken", valid_600376
  var valid_600377 = query.getOrDefault("max-results")
  valid_600377 = validateParameter(valid_600377, JInt, required = false, default = nil)
  if valid_600377 != nil:
    section.add "max-results", valid_600377
  var valid_600378 = query.getOrDefault("next-token")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "next-token", valid_600378
  var valid_600379 = query.getOrDefault("MaxResults")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "MaxResults", valid_600379
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
  var valid_600380 = header.getOrDefault("X-Amz-Date")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Date", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Security-Token")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Security-Token", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Content-Sha256", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Algorithm")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Algorithm", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Signature")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Signature", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-SignedHeaders", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Credential")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Credential", valid_600386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600387: Call_ListRoomMemberships_600371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the membership details for the specified room, such as member IDs, member email addresses, and member names.
  ## 
  let valid = call_600387.validator(path, query, header, formData, body)
  let scheme = call_600387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600387.url(scheme.get, call_600387.host, call_600387.base,
                         call_600387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600387, url, valid)

proc call*(call_600388: Call_ListRoomMemberships_600371; accountId: string;
          roomId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRoomMemberships
  ## Lists the membership details for the specified room, such as member IDs, member email addresses, and member names.
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
  var path_600389 = newJObject()
  var query_600390 = newJObject()
  add(path_600389, "accountId", newJString(accountId))
  add(query_600390, "NextToken", newJString(NextToken))
  add(query_600390, "max-results", newJInt(maxResults))
  add(query_600390, "next-token", newJString(nextToken))
  add(path_600389, "roomId", newJString(roomId))
  add(query_600390, "MaxResults", newJString(MaxResults))
  result = call_600388.call(path_600389, query_600390, nil, nil, nil)

var listRoomMemberships* = Call_ListRoomMemberships_600371(
    name: "listRoomMemberships", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships",
    validator: validate_ListRoomMemberships_600372, base: "/",
    url: url_ListRoomMemberships_600373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_600425 = ref object of OpenApiRestCall_599368
proc url_CreateVoiceConnector_600427(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnector_600426(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600428 = header.getOrDefault("X-Amz-Date")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Date", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Security-Token")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Security-Token", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Signature")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Signature", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-SignedHeaders", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Credential")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Credential", valid_600434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600436: Call_CreateVoiceConnector_600425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ## 
  let valid = call_600436.validator(path, query, header, formData, body)
  let scheme = call_600436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600436.url(scheme.get, call_600436.host, call_600436.base,
                         call_600436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600436, url, valid)

proc call*(call_600437: Call_CreateVoiceConnector_600425; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## <p>Creates an Amazon Chime Voice Connector under the administrator's AWS account. You can choose to create an Amazon Chime Voice Connector in a specific AWS Region.</p> <p>Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.</p>
  ##   body: JObject (required)
  var body_600438 = newJObject()
  if body != nil:
    body_600438 = body
  result = call_600437.call(nil, nil, nil, nil, body_600438)

var createVoiceConnector* = Call_CreateVoiceConnector_600425(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_600426, base: "/",
    url: url_CreateVoiceConnector_600427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_600408 = ref object of OpenApiRestCall_599368
proc url_ListVoiceConnectors_600410(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectors_600409(path: JsonNode; query: JsonNode;
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
  var valid_600411 = query.getOrDefault("NextToken")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "NextToken", valid_600411
  var valid_600412 = query.getOrDefault("max-results")
  valid_600412 = validateParameter(valid_600412, JInt, required = false, default = nil)
  if valid_600412 != nil:
    section.add "max-results", valid_600412
  var valid_600413 = query.getOrDefault("next-token")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "next-token", valid_600413
  var valid_600414 = query.getOrDefault("MaxResults")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "MaxResults", valid_600414
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
  var valid_600415 = header.getOrDefault("X-Amz-Date")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Date", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Security-Token")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Security-Token", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Content-Sha256", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Algorithm")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Algorithm", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Signature")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Signature", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-SignedHeaders", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Credential")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Credential", valid_600421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600422: Call_ListVoiceConnectors_600408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_600422.validator(path, query, header, formData, body)
  let scheme = call_600422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600422.url(scheme.get, call_600422.host, call_600422.base,
                         call_600422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600422, url, valid)

proc call*(call_600423: Call_ListVoiceConnectors_600408; NextToken: string = "";
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
  var query_600424 = newJObject()
  add(query_600424, "NextToken", newJString(NextToken))
  add(query_600424, "max-results", newJInt(maxResults))
  add(query_600424, "next-token", newJString(nextToken))
  add(query_600424, "MaxResults", newJString(MaxResults))
  result = call_600423.call(nil, query_600424, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_600408(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_600409, base: "/",
    url: url_ListVoiceConnectors_600410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnectorGroup_600456 = ref object of OpenApiRestCall_599368
proc url_CreateVoiceConnectorGroup_600458(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVoiceConnectorGroup_600457(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600459 = header.getOrDefault("X-Amz-Date")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Date", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Security-Token")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Security-Token", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Content-Sha256", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Algorithm")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Algorithm", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Signature")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Signature", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-SignedHeaders", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Credential")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Credential", valid_600465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600467: Call_CreateVoiceConnectorGroup_600456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ## 
  let valid = call_600467.validator(path, query, header, formData, body)
  let scheme = call_600467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600467.url(scheme.get, call_600467.host, call_600467.base,
                         call_600467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600467, url, valid)

proc call*(call_600468: Call_CreateVoiceConnectorGroup_600456; body: JsonNode): Recallable =
  ## createVoiceConnectorGroup
  ## <p>Creates an Amazon Chime Voice Connector group under the administrator's AWS account. You can associate up to three existing Amazon Chime Voice Connectors with the Amazon Chime Voice Connector group by including <code>VoiceConnectorItems</code> in the request.</p> <p>You can include Amazon Chime Voice Connectors from different AWS Regions in your group. This creates a fault tolerant mechanism for fallback in case of availability events.</p>
  ##   body: JObject (required)
  var body_600469 = newJObject()
  if body != nil:
    body_600469 = body
  result = call_600468.call(nil, nil, nil, nil, body_600469)

var createVoiceConnectorGroup* = Call_CreateVoiceConnectorGroup_600456(
    name: "createVoiceConnectorGroup", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_CreateVoiceConnectorGroup_600457, base: "/",
    url: url_CreateVoiceConnectorGroup_600458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorGroups_600439 = ref object of OpenApiRestCall_599368
proc url_ListVoiceConnectorGroups_600441(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListVoiceConnectorGroups_600440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600442 = query.getOrDefault("NextToken")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "NextToken", valid_600442
  var valid_600443 = query.getOrDefault("max-results")
  valid_600443 = validateParameter(valid_600443, JInt, required = false, default = nil)
  if valid_600443 != nil:
    section.add "max-results", valid_600443
  var valid_600444 = query.getOrDefault("next-token")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "next-token", valid_600444
  var valid_600445 = query.getOrDefault("MaxResults")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "MaxResults", valid_600445
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
  var valid_600446 = header.getOrDefault("X-Amz-Date")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Date", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Security-Token")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Security-Token", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Content-Sha256", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Algorithm")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Algorithm", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Signature")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Signature", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-SignedHeaders", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Credential")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Credential", valid_600452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600453: Call_ListVoiceConnectorGroups_600439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connector groups for the administrator's AWS account.
  ## 
  let valid = call_600453.validator(path, query, header, formData, body)
  let scheme = call_600453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600453.url(scheme.get, call_600453.host, call_600453.base,
                         call_600453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600453, url, valid)

proc call*(call_600454: Call_ListVoiceConnectorGroups_600439;
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
  var query_600455 = newJObject()
  add(query_600455, "NextToken", newJString(NextToken))
  add(query_600455, "max-results", newJInt(maxResults))
  add(query_600455, "next-token", newJString(nextToken))
  add(query_600455, "MaxResults", newJString(MaxResults))
  result = call_600454.call(nil, query_600455, nil, nil, nil)

var listVoiceConnectorGroups* = Call_ListVoiceConnectorGroups_600439(
    name: "listVoiceConnectorGroups", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connector-groups",
    validator: validate_ListVoiceConnectorGroups_600440, base: "/",
    url: url_ListVoiceConnectorGroups_600441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_600484 = ref object of OpenApiRestCall_599368
proc url_UpdateAccount_600486(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccount_600485(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600487 = path.getOrDefault("accountId")
  valid_600487 = validateParameter(valid_600487, JString, required = true,
                                 default = nil)
  if valid_600487 != nil:
    section.add "accountId", valid_600487
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
  var valid_600488 = header.getOrDefault("X-Amz-Date")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Date", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Security-Token")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Security-Token", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Content-Sha256", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Algorithm")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Algorithm", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Signature")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Signature", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-SignedHeaders", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Credential")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Credential", valid_600494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600496: Call_UpdateAccount_600484; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_600496.validator(path, query, header, formData, body)
  let scheme = call_600496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600496.url(scheme.get, call_600496.host, call_600496.base,
                         call_600496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600496, url, valid)

proc call*(call_600497: Call_UpdateAccount_600484; accountId: string; body: JsonNode): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_600498 = newJObject()
  var body_600499 = newJObject()
  add(path_600498, "accountId", newJString(accountId))
  if body != nil:
    body_600499 = body
  result = call_600497.call(path_600498, nil, nil, nil, body_600499)

var updateAccount* = Call_UpdateAccount_600484(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_600485,
    base: "/", url: url_UpdateAccount_600486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_600470 = ref object of OpenApiRestCall_599368
proc url_GetAccount_600472(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAccount_600471(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600473 = path.getOrDefault("accountId")
  valid_600473 = validateParameter(valid_600473, JString, required = true,
                                 default = nil)
  if valid_600473 != nil:
    section.add "accountId", valid_600473
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
  var valid_600474 = header.getOrDefault("X-Amz-Date")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Date", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Security-Token")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Security-Token", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Content-Sha256", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Algorithm")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Algorithm", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-Signature")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Signature", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-SignedHeaders", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Credential")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Credential", valid_600480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600481: Call_GetAccount_600470; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_600481.validator(path, query, header, formData, body)
  let scheme = call_600481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600481.url(scheme.get, call_600481.host, call_600481.base,
                         call_600481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600481, url, valid)

proc call*(call_600482: Call_GetAccount_600470; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_600483 = newJObject()
  add(path_600483, "accountId", newJString(accountId))
  result = call_600482.call(path_600483, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_600470(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_600471,
                                      base: "/", url: url_GetAccount_600472,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_600500 = ref object of OpenApiRestCall_599368
proc url_DeleteAccount_600502(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccount_600501(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600503 = path.getOrDefault("accountId")
  valid_600503 = validateParameter(valid_600503, JString, required = true,
                                 default = nil)
  if valid_600503 != nil:
    section.add "accountId", valid_600503
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
  var valid_600504 = header.getOrDefault("X-Amz-Date")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Date", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Security-Token")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Security-Token", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Content-Sha256", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Algorithm")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Algorithm", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Signature")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Signature", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-SignedHeaders", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Credential")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Credential", valid_600510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_DeleteAccount_600500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_DeleteAccount_600500; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_600513 = newJObject()
  add(path_600513, "accountId", newJString(accountId))
  result = call_600512.call(path_600513, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_600500(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_600501,
    base: "/", url: url_DeleteAccount_600502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttendee_600514 = ref object of OpenApiRestCall_599368
proc url_GetAttendee_600516(protocol: Scheme; host: string; base: string;
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

proc validate_GetAttendee_600515(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600517 = path.getOrDefault("attendeeId")
  valid_600517 = validateParameter(valid_600517, JString, required = true,
                                 default = nil)
  if valid_600517 != nil:
    section.add "attendeeId", valid_600517
  var valid_600518 = path.getOrDefault("meetingId")
  valid_600518 = validateParameter(valid_600518, JString, required = true,
                                 default = nil)
  if valid_600518 != nil:
    section.add "meetingId", valid_600518
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
  var valid_600519 = header.getOrDefault("X-Amz-Date")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Date", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Security-Token")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Security-Token", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Content-Sha256", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Algorithm")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Algorithm", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Signature")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Signature", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-SignedHeaders", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Credential")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Credential", valid_600525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_GetAttendee_600514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_GetAttendee_600514; attendeeId: string;
          meetingId: string): Recallable =
  ## getAttendee
  ## Gets the Amazon Chime SDK attendee details for a specified meeting ID and attendee ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_600528 = newJObject()
  add(path_600528, "attendeeId", newJString(attendeeId))
  add(path_600528, "meetingId", newJString(meetingId))
  result = call_600527.call(path_600528, nil, nil, nil, nil)

var getAttendee* = Call_GetAttendee_600514(name: "getAttendee",
                                        meth: HttpMethod.HttpGet,
                                        host: "chime.amazonaws.com", route: "/meetings/{meetingId}/attendees/{attendeeId}",
                                        validator: validate_GetAttendee_600515,
                                        base: "/", url: url_GetAttendee_600516,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttendee_600529 = ref object of OpenApiRestCall_599368
proc url_DeleteAttendee_600531(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAttendee_600530(path: JsonNode; query: JsonNode;
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
  var valid_600532 = path.getOrDefault("attendeeId")
  valid_600532 = validateParameter(valid_600532, JString, required = true,
                                 default = nil)
  if valid_600532 != nil:
    section.add "attendeeId", valid_600532
  var valid_600533 = path.getOrDefault("meetingId")
  valid_600533 = validateParameter(valid_600533, JString, required = true,
                                 default = nil)
  if valid_600533 != nil:
    section.add "meetingId", valid_600533
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
  var valid_600534 = header.getOrDefault("X-Amz-Date")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Date", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Security-Token")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Security-Token", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Content-Sha256", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Algorithm")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Algorithm", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Signature")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Signature", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-SignedHeaders", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Credential")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Credential", valid_600540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600541: Call_DeleteAttendee_600529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600541.validator(path, query, header, formData, body)
  let scheme = call_600541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600541.url(scheme.get, call_600541.host, call_600541.base,
                         call_600541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600541, url, valid)

proc call*(call_600542: Call_DeleteAttendee_600529; attendeeId: string;
          meetingId: string): Recallable =
  ## deleteAttendee
  ## Deletes an attendee from the specified Amazon Chime SDK meeting and deletes their <code>JoinToken</code>. Attendees are automatically deleted when a Amazon Chime SDK meeting is deleted. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   attendeeId: string (required)
  ##             : The Amazon Chime SDK attendee ID.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_600543 = newJObject()
  add(path_600543, "attendeeId", newJString(attendeeId))
  add(path_600543, "meetingId", newJString(meetingId))
  result = call_600542.call(path_600543, nil, nil, nil, nil)

var deleteAttendee* = Call_DeleteAttendee_600529(name: "deleteAttendee",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}/attendees/{attendeeId}",
    validator: validate_DeleteAttendee_600530, base: "/", url: url_DeleteAttendee_600531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_600559 = ref object of OpenApiRestCall_599368
proc url_PutEventsConfiguration_600561(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventsConfiguration_600560(path: JsonNode; query: JsonNode;
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
  var valid_600562 = path.getOrDefault("accountId")
  valid_600562 = validateParameter(valid_600562, JString, required = true,
                                 default = nil)
  if valid_600562 != nil:
    section.add "accountId", valid_600562
  var valid_600563 = path.getOrDefault("botId")
  valid_600563 = validateParameter(valid_600563, JString, required = true,
                                 default = nil)
  if valid_600563 != nil:
    section.add "botId", valid_600563
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
  var valid_600564 = header.getOrDefault("X-Amz-Date")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Date", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Security-Token")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Security-Token", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Content-Sha256", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Algorithm")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Algorithm", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-Signature")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Signature", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-SignedHeaders", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Credential")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Credential", valid_600570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600572: Call_PutEventsConfiguration_600559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_600572.validator(path, query, header, formData, body)
  let scheme = call_600572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600572.url(scheme.get, call_600572.host, call_600572.base,
                         call_600572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600572, url, valid)

proc call*(call_600573: Call_PutEventsConfiguration_600559; accountId: string;
          botId: string; body: JsonNode): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_600574 = newJObject()
  var body_600575 = newJObject()
  add(path_600574, "accountId", newJString(accountId))
  add(path_600574, "botId", newJString(botId))
  if body != nil:
    body_600575 = body
  result = call_600573.call(path_600574, nil, nil, nil, body_600575)

var putEventsConfiguration* = Call_PutEventsConfiguration_600559(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_600560, base: "/",
    url: url_PutEventsConfiguration_600561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_600544 = ref object of OpenApiRestCall_599368
proc url_GetEventsConfiguration_600546(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventsConfiguration_600545(path: JsonNode; query: JsonNode;
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
  var valid_600547 = path.getOrDefault("accountId")
  valid_600547 = validateParameter(valid_600547, JString, required = true,
                                 default = nil)
  if valid_600547 != nil:
    section.add "accountId", valid_600547
  var valid_600548 = path.getOrDefault("botId")
  valid_600548 = validateParameter(valid_600548, JString, required = true,
                                 default = nil)
  if valid_600548 != nil:
    section.add "botId", valid_600548
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
  var valid_600549 = header.getOrDefault("X-Amz-Date")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Date", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Security-Token")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Security-Token", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Content-Sha256", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Algorithm")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Algorithm", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-Signature")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Signature", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-SignedHeaders", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Credential")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Credential", valid_600555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600556: Call_GetEventsConfiguration_600544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_600556.validator(path, query, header, formData, body)
  let scheme = call_600556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600556.url(scheme.get, call_600556.host, call_600556.base,
                         call_600556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600556, url, valid)

proc call*(call_600557: Call_GetEventsConfiguration_600544; accountId: string;
          botId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_600558 = newJObject()
  add(path_600558, "accountId", newJString(accountId))
  add(path_600558, "botId", newJString(botId))
  result = call_600557.call(path_600558, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_600544(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_600545, base: "/",
    url: url_GetEventsConfiguration_600546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_600576 = ref object of OpenApiRestCall_599368
proc url_DeleteEventsConfiguration_600578(protocol: Scheme; host: string;
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

proc validate_DeleteEventsConfiguration_600577(path: JsonNode; query: JsonNode;
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
  var valid_600579 = path.getOrDefault("accountId")
  valid_600579 = validateParameter(valid_600579, JString, required = true,
                                 default = nil)
  if valid_600579 != nil:
    section.add "accountId", valid_600579
  var valid_600580 = path.getOrDefault("botId")
  valid_600580 = validateParameter(valid_600580, JString, required = true,
                                 default = nil)
  if valid_600580 != nil:
    section.add "botId", valid_600580
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
  var valid_600581 = header.getOrDefault("X-Amz-Date")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Date", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Security-Token")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Security-Token", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Content-Sha256", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Algorithm")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Algorithm", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Signature")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Signature", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-SignedHeaders", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Credential")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Credential", valid_600587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600588: Call_DeleteEventsConfiguration_600576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_600588.validator(path, query, header, formData, body)
  let scheme = call_600588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600588.url(scheme.get, call_600588.host, call_600588.base,
                         call_600588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600588, url, valid)

proc call*(call_600589: Call_DeleteEventsConfiguration_600576; accountId: string;
          botId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_600590 = newJObject()
  add(path_600590, "accountId", newJString(accountId))
  add(path_600590, "botId", newJString(botId))
  result = call_600589.call(path_600590, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_600576(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_600577, base: "/",
    url: url_DeleteEventsConfiguration_600578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMeeting_600591 = ref object of OpenApiRestCall_599368
proc url_GetMeeting_600593(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMeeting_600592(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600594 = path.getOrDefault("meetingId")
  valid_600594 = validateParameter(valid_600594, JString, required = true,
                                 default = nil)
  if valid_600594 != nil:
    section.add "meetingId", valid_600594
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
  var valid_600595 = header.getOrDefault("X-Amz-Date")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Date", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Security-Token")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Security-Token", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Content-Sha256", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-Algorithm")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Algorithm", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Signature")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Signature", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-SignedHeaders", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-Credential")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Credential", valid_600601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600602: Call_GetMeeting_600591; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600602.validator(path, query, header, formData, body)
  let scheme = call_600602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600602.url(scheme.get, call_600602.host, call_600602.base,
                         call_600602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600602, url, valid)

proc call*(call_600603: Call_GetMeeting_600591; meetingId: string): Recallable =
  ## getMeeting
  ## Gets the Amazon Chime SDK meeting details for the specified meeting ID. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_600604 = newJObject()
  add(path_600604, "meetingId", newJString(meetingId))
  result = call_600603.call(path_600604, nil, nil, nil, nil)

var getMeeting* = Call_GetMeeting_600591(name: "getMeeting",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/meetings/{meetingId}",
                                      validator: validate_GetMeeting_600592,
                                      base: "/", url: url_GetMeeting_600593,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMeeting_600605 = ref object of OpenApiRestCall_599368
proc url_DeleteMeeting_600607(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMeeting_600606(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600608 = path.getOrDefault("meetingId")
  valid_600608 = validateParameter(valid_600608, JString, required = true,
                                 default = nil)
  if valid_600608 != nil:
    section.add "meetingId", valid_600608
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
  var valid_600609 = header.getOrDefault("X-Amz-Date")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Date", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Security-Token")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Security-Token", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Content-Sha256", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Algorithm")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Algorithm", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-Signature")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-Signature", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-SignedHeaders", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-Credential")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-Credential", valid_600615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600616: Call_DeleteMeeting_600605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ## 
  let valid = call_600616.validator(path, query, header, formData, body)
  let scheme = call_600616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600616.url(scheme.get, call_600616.host, call_600616.base,
                         call_600616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600616, url, valid)

proc call*(call_600617: Call_DeleteMeeting_600605; meetingId: string): Recallable =
  ## deleteMeeting
  ## Deletes the specified Amazon Chime SDK meeting. When a meeting is deleted, its attendees are also deleted and clients can no longer join it. For more information about the Amazon Chime SDK, see <a href="https://docs.aws.amazon.com/chime/latest/dg/meetings-sdk.html">Using the Amazon Chime SDK</a> in the <i>Amazon Chime Developer Guide</i>.
  ##   meetingId: string (required)
  ##            : The Amazon Chime SDK meeting ID.
  var path_600618 = newJObject()
  add(path_600618, "meetingId", newJString(meetingId))
  result = call_600617.call(path_600618, nil, nil, nil, nil)

var deleteMeeting* = Call_DeleteMeeting_600605(name: "deleteMeeting",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/meetings/{meetingId}", validator: validate_DeleteMeeting_600606,
    base: "/", url: url_DeleteMeeting_600607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_600633 = ref object of OpenApiRestCall_599368
proc url_UpdatePhoneNumber_600635(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePhoneNumber_600634(path: JsonNode; query: JsonNode;
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
  var valid_600636 = path.getOrDefault("phoneNumberId")
  valid_600636 = validateParameter(valid_600636, JString, required = true,
                                 default = nil)
  if valid_600636 != nil:
    section.add "phoneNumberId", valid_600636
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
  var valid_600637 = header.getOrDefault("X-Amz-Date")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Date", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Security-Token")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Security-Token", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Content-Sha256", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Algorithm")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Algorithm", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Signature")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Signature", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-SignedHeaders", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Credential")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Credential", valid_600643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600645: Call_UpdatePhoneNumber_600633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ## 
  let valid = call_600645.validator(path, query, header, formData, body)
  let scheme = call_600645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600645.url(scheme.get, call_600645.host, call_600645.base,
                         call_600645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600645, url, valid)

proc call*(call_600646: Call_UpdatePhoneNumber_600633; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## <p>Updates phone number details, such as product type or calling name, for the specified phone number ID. You can update one phone number detail at a time. For example, you can update either the product type or the calling name in one action.</p> <p>For toll-free numbers, you must use the Amazon Chime Voice Connector product type.</p> <p>Updates to outbound calling names can take up to 72 hours to complete. Pending updates to outbound calling names must be complete before you can request another update.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_600647 = newJObject()
  var body_600648 = newJObject()
  add(path_600647, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_600648 = body
  result = call_600646.call(path_600647, nil, nil, nil, body_600648)

var updatePhoneNumber* = Call_UpdatePhoneNumber_600633(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_600634, base: "/",
    url: url_UpdatePhoneNumber_600635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_600619 = ref object of OpenApiRestCall_599368
proc url_GetPhoneNumber_600621(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumber_600620(path: JsonNode; query: JsonNode;
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
  var valid_600622 = path.getOrDefault("phoneNumberId")
  valid_600622 = validateParameter(valid_600622, JString, required = true,
                                 default = nil)
  if valid_600622 != nil:
    section.add "phoneNumberId", valid_600622
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
  var valid_600623 = header.getOrDefault("X-Amz-Date")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Date", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Security-Token")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Security-Token", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Content-Sha256", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Algorithm")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Algorithm", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Signature")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Signature", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-SignedHeaders", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Credential")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Credential", valid_600629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600630: Call_GetPhoneNumber_600619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_600630.validator(path, query, header, formData, body)
  let scheme = call_600630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600630.url(scheme.get, call_600630.host, call_600630.base,
                         call_600630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600630, url, valid)

proc call*(call_600631: Call_GetPhoneNumber_600619; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_600632 = newJObject()
  add(path_600632, "phoneNumberId", newJString(phoneNumberId))
  result = call_600631.call(path_600632, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_600619(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_600620,
    base: "/", url: url_GetPhoneNumber_600621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_600649 = ref object of OpenApiRestCall_599368
proc url_DeletePhoneNumber_600651(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePhoneNumber_600650(path: JsonNode; query: JsonNode;
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
  var valid_600652 = path.getOrDefault("phoneNumberId")
  valid_600652 = validateParameter(valid_600652, JString, required = true,
                                 default = nil)
  if valid_600652 != nil:
    section.add "phoneNumberId", valid_600652
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
  var valid_600653 = header.getOrDefault("X-Amz-Date")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Date", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Security-Token")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Security-Token", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Content-Sha256", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Algorithm")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Algorithm", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Signature")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Signature", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-SignedHeaders", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-Credential")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Credential", valid_600659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600660: Call_DeletePhoneNumber_600649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_600660.validator(path, query, header, formData, body)
  let scheme = call_600660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600660.url(scheme.get, call_600660.host, call_600660.base,
                         call_600660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600660, url, valid)

proc call*(call_600661: Call_DeletePhoneNumber_600649; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_600662 = newJObject()
  add(path_600662, "phoneNumberId", newJString(phoneNumberId))
  result = call_600661.call(path_600662, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_600649(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_600650, base: "/",
    url: url_DeletePhoneNumber_600651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_600678 = ref object of OpenApiRestCall_599368
proc url_UpdateRoom_600680(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateRoom_600679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600681 = path.getOrDefault("accountId")
  valid_600681 = validateParameter(valid_600681, JString, required = true,
                                 default = nil)
  if valid_600681 != nil:
    section.add "accountId", valid_600681
  var valid_600682 = path.getOrDefault("roomId")
  valid_600682 = validateParameter(valid_600682, JString, required = true,
                                 default = nil)
  if valid_600682 != nil:
    section.add "roomId", valid_600682
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
  var valid_600683 = header.getOrDefault("X-Amz-Date")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Date", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Security-Token")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Security-Token", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Content-Sha256", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Algorithm")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Algorithm", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Signature")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Signature", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-SignedHeaders", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Credential")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Credential", valid_600689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600691: Call_UpdateRoom_600678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details, such as the room name.
  ## 
  let valid = call_600691.validator(path, query, header, formData, body)
  let scheme = call_600691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600691.url(scheme.get, call_600691.host, call_600691.base,
                         call_600691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600691, url, valid)

proc call*(call_600692: Call_UpdateRoom_600678; accountId: string; body: JsonNode;
          roomId: string): Recallable =
  ## updateRoom
  ## Updates room details, such as the room name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_600693 = newJObject()
  var body_600694 = newJObject()
  add(path_600693, "accountId", newJString(accountId))
  if body != nil:
    body_600694 = body
  add(path_600693, "roomId", newJString(roomId))
  result = call_600692.call(path_600693, nil, nil, nil, body_600694)

var updateRoom* = Call_UpdateRoom_600678(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_UpdateRoom_600679,
                                      base: "/", url: url_UpdateRoom_600680,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_600663 = ref object of OpenApiRestCall_599368
proc url_GetRoom_600665(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoom_600664(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves room details, such as name.
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
  var valid_600666 = path.getOrDefault("accountId")
  valid_600666 = validateParameter(valid_600666, JString, required = true,
                                 default = nil)
  if valid_600666 != nil:
    section.add "accountId", valid_600666
  var valid_600667 = path.getOrDefault("roomId")
  valid_600667 = validateParameter(valid_600667, JString, required = true,
                                 default = nil)
  if valid_600667 != nil:
    section.add "roomId", valid_600667
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
  var valid_600668 = header.getOrDefault("X-Amz-Date")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Date", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Security-Token")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Security-Token", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Content-Sha256", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Algorithm")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Algorithm", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Signature")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Signature", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-SignedHeaders", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-Credential")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Credential", valid_600674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600675: Call_GetRoom_600663; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves room details, such as name.
  ## 
  let valid = call_600675.validator(path, query, header, formData, body)
  let scheme = call_600675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600675.url(scheme.get, call_600675.host, call_600675.base,
                         call_600675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600675, url, valid)

proc call*(call_600676: Call_GetRoom_600663; accountId: string; roomId: string): Recallable =
  ## getRoom
  ## Retrieves room details, such as name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_600677 = newJObject()
  add(path_600677, "accountId", newJString(accountId))
  add(path_600677, "roomId", newJString(roomId))
  result = call_600676.call(path_600677, nil, nil, nil, nil)

var getRoom* = Call_GetRoom_600663(name: "getRoom", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/rooms/{roomId}",
                                validator: validate_GetRoom_600664, base: "/",
                                url: url_GetRoom_600665,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_600695 = ref object of OpenApiRestCall_599368
proc url_DeleteRoom_600697(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteRoom_600696(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600698 = path.getOrDefault("accountId")
  valid_600698 = validateParameter(valid_600698, JString, required = true,
                                 default = nil)
  if valid_600698 != nil:
    section.add "accountId", valid_600698
  var valid_600699 = path.getOrDefault("roomId")
  valid_600699 = validateParameter(valid_600699, JString, required = true,
                                 default = nil)
  if valid_600699 != nil:
    section.add "roomId", valid_600699
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
  var valid_600700 = header.getOrDefault("X-Amz-Date")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Date", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Security-Token")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Security-Token", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Content-Sha256", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Algorithm")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Algorithm", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Signature")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Signature", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-SignedHeaders", valid_600705
  var valid_600706 = header.getOrDefault("X-Amz-Credential")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-Credential", valid_600706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600707: Call_DeleteRoom_600695; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a chat room.
  ## 
  let valid = call_600707.validator(path, query, header, formData, body)
  let scheme = call_600707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600707.url(scheme.get, call_600707.host, call_600707.base,
                         call_600707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600707, url, valid)

proc call*(call_600708: Call_DeleteRoom_600695; accountId: string; roomId: string): Recallable =
  ## deleteRoom
  ## Deletes a chat room.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The chat room ID.
  var path_600709 = newJObject()
  add(path_600709, "accountId", newJString(accountId))
  add(path_600709, "roomId", newJString(roomId))
  result = call_600708.call(path_600709, nil, nil, nil, nil)

var deleteRoom* = Call_DeleteRoom_600695(name: "deleteRoom",
                                      meth: HttpMethod.HttpDelete,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/rooms/{roomId}",
                                      validator: validate_DeleteRoom_600696,
                                      base: "/", url: url_DeleteRoom_600697,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoomMembership_600710 = ref object of OpenApiRestCall_599368
proc url_UpdateRoomMembership_600712(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoomMembership_600711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates room membership details, such as member role. The member role designates whether the member is a chat room administrator or a general chat room member. Member role can only be updated for user IDs.
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
  var valid_600713 = path.getOrDefault("memberId")
  valid_600713 = validateParameter(valid_600713, JString, required = true,
                                 default = nil)
  if valid_600713 != nil:
    section.add "memberId", valid_600713
  var valid_600714 = path.getOrDefault("accountId")
  valid_600714 = validateParameter(valid_600714, JString, required = true,
                                 default = nil)
  if valid_600714 != nil:
    section.add "accountId", valid_600714
  var valid_600715 = path.getOrDefault("roomId")
  valid_600715 = validateParameter(valid_600715, JString, required = true,
                                 default = nil)
  if valid_600715 != nil:
    section.add "roomId", valid_600715
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
  var valid_600716 = header.getOrDefault("X-Amz-Date")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Date", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Security-Token")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Security-Token", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Content-Sha256", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-Algorithm")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Algorithm", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Signature")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Signature", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-SignedHeaders", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-Credential")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Credential", valid_600722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600724: Call_UpdateRoomMembership_600710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room membership details, such as member role. The member role designates whether the member is a chat room administrator or a general chat room member. Member role can only be updated for user IDs.
  ## 
  let valid = call_600724.validator(path, query, header, formData, body)
  let scheme = call_600724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600724.url(scheme.get, call_600724.host, call_600724.base,
                         call_600724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600724, url, valid)

proc call*(call_600725: Call_UpdateRoomMembership_600710; memberId: string;
          accountId: string; body: JsonNode; roomId: string): Recallable =
  ## updateRoomMembership
  ## Updates room membership details, such as member role. The member role designates whether the member is a chat room administrator or a general chat room member. Member role can only be updated for user IDs.
  ##   memberId: string (required)
  ##           : The member ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   roomId: string (required)
  ##         : The room ID.
  var path_600726 = newJObject()
  var body_600727 = newJObject()
  add(path_600726, "memberId", newJString(memberId))
  add(path_600726, "accountId", newJString(accountId))
  if body != nil:
    body_600727 = body
  add(path_600726, "roomId", newJString(roomId))
  result = call_600725.call(path_600726, nil, nil, nil, body_600727)

var updateRoomMembership* = Call_UpdateRoomMembership_600710(
    name: "updateRoomMembership", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_UpdateRoomMembership_600711, base: "/",
    url: url_UpdateRoomMembership_600712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomMembership_600728 = ref object of OpenApiRestCall_599368
proc url_DeleteRoomMembership_600730(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoomMembership_600729(path: JsonNode; query: JsonNode;
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
  var valid_600731 = path.getOrDefault("memberId")
  valid_600731 = validateParameter(valid_600731, JString, required = true,
                                 default = nil)
  if valid_600731 != nil:
    section.add "memberId", valid_600731
  var valid_600732 = path.getOrDefault("accountId")
  valid_600732 = validateParameter(valid_600732, JString, required = true,
                                 default = nil)
  if valid_600732 != nil:
    section.add "accountId", valid_600732
  var valid_600733 = path.getOrDefault("roomId")
  valid_600733 = validateParameter(valid_600733, JString, required = true,
                                 default = nil)
  if valid_600733 != nil:
    section.add "roomId", valid_600733
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
  var valid_600734 = header.getOrDefault("X-Amz-Date")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Date", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Security-Token")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Security-Token", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Content-Sha256", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Algorithm")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Algorithm", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Signature")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Signature", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-SignedHeaders", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Credential")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Credential", valid_600740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600741: Call_DeleteRoomMembership_600728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a member from a chat room.
  ## 
  let valid = call_600741.validator(path, query, header, formData, body)
  let scheme = call_600741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600741.url(scheme.get, call_600741.host, call_600741.base,
                         call_600741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600741, url, valid)

proc call*(call_600742: Call_DeleteRoomMembership_600728; memberId: string;
          accountId: string; roomId: string): Recallable =
  ## deleteRoomMembership
  ## Removes a member from a chat room.
  ##   memberId: string (required)
  ##           : The member ID (user ID or bot ID).
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   roomId: string (required)
  ##         : The room ID.
  var path_600743 = newJObject()
  add(path_600743, "memberId", newJString(memberId))
  add(path_600743, "accountId", newJString(accountId))
  add(path_600743, "roomId", newJString(roomId))
  result = call_600742.call(path_600743, nil, nil, nil, nil)

var deleteRoomMembership* = Call_DeleteRoomMembership_600728(
    name: "deleteRoomMembership", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/rooms/{roomId}/memberships/{memberId}",
    validator: validate_DeleteRoomMembership_600729, base: "/",
    url: url_DeleteRoomMembership_600730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_600758 = ref object of OpenApiRestCall_599368
proc url_UpdateVoiceConnector_600760(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVoiceConnector_600759(path: JsonNode; query: JsonNode;
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
  var valid_600761 = path.getOrDefault("voiceConnectorId")
  valid_600761 = validateParameter(valid_600761, JString, required = true,
                                 default = nil)
  if valid_600761 != nil:
    section.add "voiceConnectorId", valid_600761
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
  var valid_600762 = header.getOrDefault("X-Amz-Date")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Date", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Security-Token")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Security-Token", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Content-Sha256", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Algorithm")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Algorithm", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-Signature")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Signature", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-SignedHeaders", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-Credential")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Credential", valid_600768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600770: Call_UpdateVoiceConnector_600758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600770.validator(path, query, header, formData, body)
  let scheme = call_600770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600770.url(scheme.get, call_600770.host, call_600770.base,
                         call_600770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600770, url, valid)

proc call*(call_600771: Call_UpdateVoiceConnector_600758; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_600772 = newJObject()
  var body_600773 = newJObject()
  add(path_600772, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_600773 = body
  result = call_600771.call(path_600772, nil, nil, nil, body_600773)

var updateVoiceConnector* = Call_UpdateVoiceConnector_600758(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_600759, base: "/",
    url: url_UpdateVoiceConnector_600760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_600744 = ref object of OpenApiRestCall_599368
proc url_GetVoiceConnector_600746(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnector_600745(path: JsonNode; query: JsonNode;
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
  var valid_600747 = path.getOrDefault("voiceConnectorId")
  valid_600747 = validateParameter(valid_600747, JString, required = true,
                                 default = nil)
  if valid_600747 != nil:
    section.add "voiceConnectorId", valid_600747
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
  var valid_600748 = header.getOrDefault("X-Amz-Date")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Date", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Security-Token")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Security-Token", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Content-Sha256", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-Algorithm")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Algorithm", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Signature")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Signature", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-SignedHeaders", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Credential")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Credential", valid_600754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600755: Call_GetVoiceConnector_600744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_600755.validator(path, query, header, formData, body)
  let scheme = call_600755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600755.url(scheme.get, call_600755.host, call_600755.base,
                         call_600755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600755, url, valid)

proc call*(call_600756: Call_GetVoiceConnector_600744; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600757 = newJObject()
  add(path_600757, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600756.call(path_600757, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_600744(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_600745, base: "/",
    url: url_GetVoiceConnector_600746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_600774 = ref object of OpenApiRestCall_599368
proc url_DeleteVoiceConnector_600776(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVoiceConnector_600775(path: JsonNode; query: JsonNode;
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
  var valid_600777 = path.getOrDefault("voiceConnectorId")
  valid_600777 = validateParameter(valid_600777, JString, required = true,
                                 default = nil)
  if valid_600777 != nil:
    section.add "voiceConnectorId", valid_600777
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
  var valid_600778 = header.getOrDefault("X-Amz-Date")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Date", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Security-Token")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Security-Token", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-Content-Sha256", valid_600780
  var valid_600781 = header.getOrDefault("X-Amz-Algorithm")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "X-Amz-Algorithm", valid_600781
  var valid_600782 = header.getOrDefault("X-Amz-Signature")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Signature", valid_600782
  var valid_600783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-SignedHeaders", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Credential")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Credential", valid_600784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600785: Call_DeleteVoiceConnector_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ## 
  let valid = call_600785.validator(path, query, header, formData, body)
  let scheme = call_600785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600785.url(scheme.get, call_600785.host, call_600785.base,
                         call_600785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600785, url, valid)

proc call*(call_600786: Call_DeleteVoiceConnector_600774; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers associated with the Amazon Chime Voice Connector must be disassociated from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600787 = newJObject()
  add(path_600787, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600786.call(path_600787, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_600774(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_600775, base: "/",
    url: url_DeleteVoiceConnector_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnectorGroup_600802 = ref object of OpenApiRestCall_599368
proc url_UpdateVoiceConnectorGroup_600804(protocol: Scheme; host: string;
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

proc validate_UpdateVoiceConnectorGroup_600803(path: JsonNode; query: JsonNode;
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
  var valid_600805 = path.getOrDefault("voiceConnectorGroupId")
  valid_600805 = validateParameter(valid_600805, JString, required = true,
                                 default = nil)
  if valid_600805 != nil:
    section.add "voiceConnectorGroupId", valid_600805
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
  var valid_600806 = header.getOrDefault("X-Amz-Date")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Date", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-Security-Token")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-Security-Token", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-Content-Sha256", valid_600808
  var valid_600809 = header.getOrDefault("X-Amz-Algorithm")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-Algorithm", valid_600809
  var valid_600810 = header.getOrDefault("X-Amz-Signature")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "X-Amz-Signature", valid_600810
  var valid_600811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-SignedHeaders", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-Credential")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Credential", valid_600812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600814: Call_UpdateVoiceConnectorGroup_600802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ## 
  let valid = call_600814.validator(path, query, header, formData, body)
  let scheme = call_600814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600814.url(scheme.get, call_600814.host, call_600814.base,
                         call_600814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600814, url, valid)

proc call*(call_600815: Call_UpdateVoiceConnectorGroup_600802;
          voiceConnectorGroupId: string; body: JsonNode): Recallable =
  ## updateVoiceConnectorGroup
  ## Updates details for the specified Amazon Chime Voice Connector group, such as the name and Amazon Chime Voice Connector priority ranking.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   body: JObject (required)
  var path_600816 = newJObject()
  var body_600817 = newJObject()
  add(path_600816, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  if body != nil:
    body_600817 = body
  result = call_600815.call(path_600816, nil, nil, nil, body_600817)

var updateVoiceConnectorGroup* = Call_UpdateVoiceConnectorGroup_600802(
    name: "updateVoiceConnectorGroup", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_UpdateVoiceConnectorGroup_600803, base: "/",
    url: url_UpdateVoiceConnectorGroup_600804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorGroup_600788 = ref object of OpenApiRestCall_599368
proc url_GetVoiceConnectorGroup_600790(protocol: Scheme; host: string; base: string;
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

proc validate_GetVoiceConnectorGroup_600789(path: JsonNode; query: JsonNode;
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
  var valid_600791 = path.getOrDefault("voiceConnectorGroupId")
  valid_600791 = validateParameter(valid_600791, JString, required = true,
                                 default = nil)
  if valid_600791 != nil:
    section.add "voiceConnectorGroupId", valid_600791
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
  var valid_600792 = header.getOrDefault("X-Amz-Date")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-Date", valid_600792
  var valid_600793 = header.getOrDefault("X-Amz-Security-Token")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "X-Amz-Security-Token", valid_600793
  var valid_600794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Content-Sha256", valid_600794
  var valid_600795 = header.getOrDefault("X-Amz-Algorithm")
  valid_600795 = validateParameter(valid_600795, JString, required = false,
                                 default = nil)
  if valid_600795 != nil:
    section.add "X-Amz-Algorithm", valid_600795
  var valid_600796 = header.getOrDefault("X-Amz-Signature")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "X-Amz-Signature", valid_600796
  var valid_600797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-SignedHeaders", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Credential")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Credential", valid_600798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600799: Call_GetVoiceConnectorGroup_600788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ## 
  let valid = call_600799.validator(path, query, header, formData, body)
  let scheme = call_600799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600799.url(scheme.get, call_600799.host, call_600799.base,
                         call_600799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600799, url, valid)

proc call*(call_600800: Call_GetVoiceConnectorGroup_600788;
          voiceConnectorGroupId: string): Recallable =
  ## getVoiceConnectorGroup
  ## Retrieves details for the specified Amazon Chime Voice Connector group, such as timestamps, name, and associated <code>VoiceConnectorItems</code>.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_600801 = newJObject()
  add(path_600801, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_600800.call(path_600801, nil, nil, nil, nil)

var getVoiceConnectorGroup* = Call_GetVoiceConnectorGroup_600788(
    name: "getVoiceConnectorGroup", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_GetVoiceConnectorGroup_600789, base: "/",
    url: url_GetVoiceConnectorGroup_600790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorGroup_600818 = ref object of OpenApiRestCall_599368
proc url_DeleteVoiceConnectorGroup_600820(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorGroup_600819(path: JsonNode; query: JsonNode;
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
  var valid_600821 = path.getOrDefault("voiceConnectorGroupId")
  valid_600821 = validateParameter(valid_600821, JString, required = true,
                                 default = nil)
  if valid_600821 != nil:
    section.add "voiceConnectorGroupId", valid_600821
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
  var valid_600822 = header.getOrDefault("X-Amz-Date")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Date", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-Security-Token")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-Security-Token", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Content-Sha256", valid_600824
  var valid_600825 = header.getOrDefault("X-Amz-Algorithm")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-Algorithm", valid_600825
  var valid_600826 = header.getOrDefault("X-Amz-Signature")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "X-Amz-Signature", valid_600826
  var valid_600827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-SignedHeaders", valid_600827
  var valid_600828 = header.getOrDefault("X-Amz-Credential")
  valid_600828 = validateParameter(valid_600828, JString, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "X-Amz-Credential", valid_600828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600829: Call_DeleteVoiceConnectorGroup_600818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ## 
  let valid = call_600829.validator(path, query, header, formData, body)
  let scheme = call_600829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600829.url(scheme.get, call_600829.host, call_600829.base,
                         call_600829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600829, url, valid)

proc call*(call_600830: Call_DeleteVoiceConnectorGroup_600818;
          voiceConnectorGroupId: string): Recallable =
  ## deleteVoiceConnectorGroup
  ## Deletes the specified Amazon Chime Voice Connector group. Any <code>VoiceConnectorItems</code> and phone numbers associated with the group must be removed before it can be deleted.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  var path_600831 = newJObject()
  add(path_600831, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  result = call_600830.call(path_600831, nil, nil, nil, nil)

var deleteVoiceConnectorGroup* = Call_DeleteVoiceConnectorGroup_600818(
    name: "deleteVoiceConnectorGroup", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connector-groups/{voiceConnectorGroupId}",
    validator: validate_DeleteVoiceConnectorGroup_600819, base: "/",
    url: url_DeleteVoiceConnectorGroup_600820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_600846 = ref object of OpenApiRestCall_599368
proc url_PutVoiceConnectorOrigination_600848(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorOrigination_600847(path: JsonNode; query: JsonNode;
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
  var valid_600849 = path.getOrDefault("voiceConnectorId")
  valid_600849 = validateParameter(valid_600849, JString, required = true,
                                 default = nil)
  if valid_600849 != nil:
    section.add "voiceConnectorId", valid_600849
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
  var valid_600850 = header.getOrDefault("X-Amz-Date")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Date", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Security-Token")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Security-Token", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Content-Sha256", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Algorithm")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Algorithm", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Signature")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Signature", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-SignedHeaders", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Credential")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Credential", valid_600856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600858: Call_PutVoiceConnectorOrigination_600846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600858.validator(path, query, header, formData, body)
  let scheme = call_600858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600858.url(scheme.get, call_600858.host, call_600858.base,
                         call_600858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600858, url, valid)

proc call*(call_600859: Call_PutVoiceConnectorOrigination_600846;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_600860 = newJObject()
  var body_600861 = newJObject()
  add(path_600860, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_600861 = body
  result = call_600859.call(path_600860, nil, nil, nil, body_600861)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_600846(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_600847, base: "/",
    url: url_PutVoiceConnectorOrigination_600848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_600832 = ref object of OpenApiRestCall_599368
proc url_GetVoiceConnectorOrigination_600834(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorOrigination_600833(path: JsonNode; query: JsonNode;
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
  var valid_600835 = path.getOrDefault("voiceConnectorId")
  valid_600835 = validateParameter(valid_600835, JString, required = true,
                                 default = nil)
  if valid_600835 != nil:
    section.add "voiceConnectorId", valid_600835
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
  var valid_600836 = header.getOrDefault("X-Amz-Date")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Date", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Security-Token")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Security-Token", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Content-Sha256", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Algorithm")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Algorithm", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Signature")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Signature", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-SignedHeaders", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Credential")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Credential", valid_600842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600843: Call_GetVoiceConnectorOrigination_600832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600843.validator(path, query, header, formData, body)
  let scheme = call_600843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600843.url(scheme.get, call_600843.host, call_600843.base,
                         call_600843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600843, url, valid)

proc call*(call_600844: Call_GetVoiceConnectorOrigination_600832;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600845 = newJObject()
  add(path_600845, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600844.call(path_600845, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_600832(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_600833, base: "/",
    url: url_GetVoiceConnectorOrigination_600834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_600862 = ref object of OpenApiRestCall_599368
proc url_DeleteVoiceConnectorOrigination_600864(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorOrigination_600863(path: JsonNode;
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
  var valid_600865 = path.getOrDefault("voiceConnectorId")
  valid_600865 = validateParameter(valid_600865, JString, required = true,
                                 default = nil)
  if valid_600865 != nil:
    section.add "voiceConnectorId", valid_600865
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
  var valid_600866 = header.getOrDefault("X-Amz-Date")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-Date", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-Security-Token")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-Security-Token", valid_600867
  var valid_600868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "X-Amz-Content-Sha256", valid_600868
  var valid_600869 = header.getOrDefault("X-Amz-Algorithm")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Algorithm", valid_600869
  var valid_600870 = header.getOrDefault("X-Amz-Signature")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-Signature", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-SignedHeaders", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Credential")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Credential", valid_600872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600873: Call_DeleteVoiceConnectorOrigination_600862;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600873.validator(path, query, header, formData, body)
  let scheme = call_600873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600873.url(scheme.get, call_600873.host, call_600873.base,
                         call_600873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600873, url, valid)

proc call*(call_600874: Call_DeleteVoiceConnectorOrigination_600862;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600875 = newJObject()
  add(path_600875, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600874.call(path_600875, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_600862(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_600863, base: "/",
    url: url_DeleteVoiceConnectorOrigination_600864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorStreamingConfiguration_600890 = ref object of OpenApiRestCall_599368
proc url_PutVoiceConnectorStreamingConfiguration_600892(protocol: Scheme;
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

proc validate_PutVoiceConnectorStreamingConfiguration_600891(path: JsonNode;
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
  var valid_600893 = path.getOrDefault("voiceConnectorId")
  valid_600893 = validateParameter(valid_600893, JString, required = true,
                                 default = nil)
  if valid_600893 != nil:
    section.add "voiceConnectorId", valid_600893
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
  var valid_600894 = header.getOrDefault("X-Amz-Date")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Date", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Security-Token")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Security-Token", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Content-Sha256", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Algorithm")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Algorithm", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Signature")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Signature", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-SignedHeaders", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Credential")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Credential", valid_600900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600902: Call_PutVoiceConnectorStreamingConfiguration_600890;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_600902.validator(path, query, header, formData, body)
  let scheme = call_600902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600902.url(scheme.get, call_600902.host, call_600902.base,
                         call_600902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600902, url, valid)

proc call*(call_600903: Call_PutVoiceConnectorStreamingConfiguration_600890;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorStreamingConfiguration
  ## Adds a streaming configuration for the specified Amazon Chime Voice Connector. The streaming configuration specifies whether media streaming is enabled for sending to Amazon Kinesis. It also sets the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_600904 = newJObject()
  var body_600905 = newJObject()
  add(path_600904, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_600905 = body
  result = call_600903.call(path_600904, nil, nil, nil, body_600905)

var putVoiceConnectorStreamingConfiguration* = Call_PutVoiceConnectorStreamingConfiguration_600890(
    name: "putVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_PutVoiceConnectorStreamingConfiguration_600891, base: "/",
    url: url_PutVoiceConnectorStreamingConfiguration_600892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorStreamingConfiguration_600876 = ref object of OpenApiRestCall_599368
proc url_GetVoiceConnectorStreamingConfiguration_600878(protocol: Scheme;
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

proc validate_GetVoiceConnectorStreamingConfiguration_600877(path: JsonNode;
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
  var valid_600879 = path.getOrDefault("voiceConnectorId")
  valid_600879 = validateParameter(valid_600879, JString, required = true,
                                 default = nil)
  if valid_600879 != nil:
    section.add "voiceConnectorId", valid_600879
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
  var valid_600880 = header.getOrDefault("X-Amz-Date")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "X-Amz-Date", valid_600880
  var valid_600881 = header.getOrDefault("X-Amz-Security-Token")
  valid_600881 = validateParameter(valid_600881, JString, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "X-Amz-Security-Token", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Content-Sha256", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Algorithm")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Algorithm", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Signature")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Signature", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-SignedHeaders", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Credential")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Credential", valid_600886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600887: Call_GetVoiceConnectorStreamingConfiguration_600876;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ## 
  let valid = call_600887.validator(path, query, header, formData, body)
  let scheme = call_600887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600887.url(scheme.get, call_600887.host, call_600887.base,
                         call_600887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600887, url, valid)

proc call*(call_600888: Call_GetVoiceConnectorStreamingConfiguration_600876;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorStreamingConfiguration
  ## Retrieves the streaming configuration details for the specified Amazon Chime Voice Connector. Shows whether media streaming is enabled for sending to Amazon Kinesis. It also shows the retention period, in hours, for the Amazon Kinesis data.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600889 = newJObject()
  add(path_600889, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600888.call(path_600889, nil, nil, nil, nil)

var getVoiceConnectorStreamingConfiguration* = Call_GetVoiceConnectorStreamingConfiguration_600876(
    name: "getVoiceConnectorStreamingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_GetVoiceConnectorStreamingConfiguration_600877, base: "/",
    url: url_GetVoiceConnectorStreamingConfiguration_600878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorStreamingConfiguration_600906 = ref object of OpenApiRestCall_599368
proc url_DeleteVoiceConnectorStreamingConfiguration_600908(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorStreamingConfiguration_600907(path: JsonNode;
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
  var valid_600909 = path.getOrDefault("voiceConnectorId")
  valid_600909 = validateParameter(valid_600909, JString, required = true,
                                 default = nil)
  if valid_600909 != nil:
    section.add "voiceConnectorId", valid_600909
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
  var valid_600910 = header.getOrDefault("X-Amz-Date")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Date", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Security-Token")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Security-Token", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Content-Sha256", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-Algorithm")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-Algorithm", valid_600913
  var valid_600914 = header.getOrDefault("X-Amz-Signature")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Signature", valid_600914
  var valid_600915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-SignedHeaders", valid_600915
  var valid_600916 = header.getOrDefault("X-Amz-Credential")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "X-Amz-Credential", valid_600916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600917: Call_DeleteVoiceConnectorStreamingConfiguration_600906;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600917.validator(path, query, header, formData, body)
  let scheme = call_600917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600917.url(scheme.get, call_600917.host, call_600917.base,
                         call_600917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600917, url, valid)

proc call*(call_600918: Call_DeleteVoiceConnectorStreamingConfiguration_600906;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorStreamingConfiguration
  ## Deletes the streaming configuration for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600919 = newJObject()
  add(path_600919, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600918.call(path_600919, nil, nil, nil, nil)

var deleteVoiceConnectorStreamingConfiguration* = Call_DeleteVoiceConnectorStreamingConfiguration_600906(
    name: "deleteVoiceConnectorStreamingConfiguration",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/streaming-configuration",
    validator: validate_DeleteVoiceConnectorStreamingConfiguration_600907,
    base: "/", url: url_DeleteVoiceConnectorStreamingConfiguration_600908,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_600934 = ref object of OpenApiRestCall_599368
proc url_PutVoiceConnectorTermination_600936(protocol: Scheme; host: string;
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

proc validate_PutVoiceConnectorTermination_600935(path: JsonNode; query: JsonNode;
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
  var valid_600937 = path.getOrDefault("voiceConnectorId")
  valid_600937 = validateParameter(valid_600937, JString, required = true,
                                 default = nil)
  if valid_600937 != nil:
    section.add "voiceConnectorId", valid_600937
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
  var valid_600938 = header.getOrDefault("X-Amz-Date")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Date", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-Security-Token")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-Security-Token", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Content-Sha256", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Algorithm")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Algorithm", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-Signature")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Signature", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-SignedHeaders", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Credential")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Credential", valid_600944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600946: Call_PutVoiceConnectorTermination_600934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600946.validator(path, query, header, formData, body)
  let scheme = call_600946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600946.url(scheme.get, call_600946.host, call_600946.base,
                         call_600946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600946, url, valid)

proc call*(call_600947: Call_PutVoiceConnectorTermination_600934;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_600948 = newJObject()
  var body_600949 = newJObject()
  add(path_600948, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_600949 = body
  result = call_600947.call(path_600948, nil, nil, nil, body_600949)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_600934(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_600935, base: "/",
    url: url_PutVoiceConnectorTermination_600936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_600920 = ref object of OpenApiRestCall_599368
proc url_GetVoiceConnectorTermination_600922(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTermination_600921(path: JsonNode; query: JsonNode;
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
  var valid_600923 = path.getOrDefault("voiceConnectorId")
  valid_600923 = validateParameter(valid_600923, JString, required = true,
                                 default = nil)
  if valid_600923 != nil:
    section.add "voiceConnectorId", valid_600923
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
  var valid_600924 = header.getOrDefault("X-Amz-Date")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Date", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Security-Token")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Security-Token", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Content-Sha256", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Algorithm")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Algorithm", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-Signature")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-Signature", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-SignedHeaders", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-Credential")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Credential", valid_600930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600931: Call_GetVoiceConnectorTermination_600920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600931.validator(path, query, header, formData, body)
  let scheme = call_600931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600931.url(scheme.get, call_600931.host, call_600931.base,
                         call_600931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600931, url, valid)

proc call*(call_600932: Call_GetVoiceConnectorTermination_600920;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600933 = newJObject()
  add(path_600933, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600932.call(path_600933, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_600920(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_600921, base: "/",
    url: url_GetVoiceConnectorTermination_600922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_600950 = ref object of OpenApiRestCall_599368
proc url_DeleteVoiceConnectorTermination_600952(protocol: Scheme; host: string;
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

proc validate_DeleteVoiceConnectorTermination_600951(path: JsonNode;
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
  var valid_600953 = path.getOrDefault("voiceConnectorId")
  valid_600953 = validateParameter(valid_600953, JString, required = true,
                                 default = nil)
  if valid_600953 != nil:
    section.add "voiceConnectorId", valid_600953
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
  var valid_600954 = header.getOrDefault("X-Amz-Date")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-Date", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Security-Token")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Security-Token", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Content-Sha256", valid_600956
  var valid_600957 = header.getOrDefault("X-Amz-Algorithm")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "X-Amz-Algorithm", valid_600957
  var valid_600958 = header.getOrDefault("X-Amz-Signature")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-Signature", valid_600958
  var valid_600959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-SignedHeaders", valid_600959
  var valid_600960 = header.getOrDefault("X-Amz-Credential")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Credential", valid_600960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600961: Call_DeleteVoiceConnectorTermination_600950;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_600961.validator(path, query, header, formData, body)
  let scheme = call_600961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600961.url(scheme.get, call_600961.host, call_600961.base,
                         call_600961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600961, url, valid)

proc call*(call_600962: Call_DeleteVoiceConnectorTermination_600950;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_600963 = newJObject()
  add(path_600963, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_600962.call(path_600963, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_600950(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_600951, base: "/",
    url: url_DeleteVoiceConnectorTermination_600952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_600964 = ref object of OpenApiRestCall_599368
proc url_DeleteVoiceConnectorTerminationCredentials_600966(protocol: Scheme;
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

proc validate_DeleteVoiceConnectorTerminationCredentials_600965(path: JsonNode;
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
  var valid_600967 = path.getOrDefault("voiceConnectorId")
  valid_600967 = validateParameter(valid_600967, JString, required = true,
                                 default = nil)
  if valid_600967 != nil:
    section.add "voiceConnectorId", valid_600967
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600968 = query.getOrDefault("operation")
  valid_600968 = validateParameter(valid_600968, JString, required = true,
                                 default = newJString("delete"))
  if valid_600968 != nil:
    section.add "operation", valid_600968
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
  var valid_600969 = header.getOrDefault("X-Amz-Date")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Date", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Security-Token")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Security-Token", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Content-Sha256", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Algorithm")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Algorithm", valid_600972
  var valid_600973 = header.getOrDefault("X-Amz-Signature")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-Signature", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-SignedHeaders", valid_600974
  var valid_600975 = header.getOrDefault("X-Amz-Credential")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Credential", valid_600975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600977: Call_DeleteVoiceConnectorTerminationCredentials_600964;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_600977.validator(path, query, header, formData, body)
  let scheme = call_600977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600977.url(scheme.get, call_600977.host, call_600977.base,
                         call_600977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600977, url, valid)

proc call*(call_600978: Call_DeleteVoiceConnectorTerminationCredentials_600964;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_600979 = newJObject()
  var query_600980 = newJObject()
  var body_600981 = newJObject()
  add(path_600979, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_600980, "operation", newJString(operation))
  if body != nil:
    body_600981 = body
  result = call_600978.call(path_600979, query_600980, nil, nil, body_600981)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_600964(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_600965,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_600966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_600982 = ref object of OpenApiRestCall_599368
proc url_DisassociatePhoneNumberFromUser_600984(protocol: Scheme; host: string;
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

proc validate_DisassociatePhoneNumberFromUser_600983(path: JsonNode;
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
  var valid_600985 = path.getOrDefault("accountId")
  valid_600985 = validateParameter(valid_600985, JString, required = true,
                                 default = nil)
  if valid_600985 != nil:
    section.add "accountId", valid_600985
  var valid_600986 = path.getOrDefault("userId")
  valid_600986 = validateParameter(valid_600986, JString, required = true,
                                 default = nil)
  if valid_600986 != nil:
    section.add "userId", valid_600986
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600987 = query.getOrDefault("operation")
  valid_600987 = validateParameter(valid_600987, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_600987 != nil:
    section.add "operation", valid_600987
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
  var valid_600988 = header.getOrDefault("X-Amz-Date")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-Date", valid_600988
  var valid_600989 = header.getOrDefault("X-Amz-Security-Token")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Security-Token", valid_600989
  var valid_600990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "X-Amz-Content-Sha256", valid_600990
  var valid_600991 = header.getOrDefault("X-Amz-Algorithm")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "X-Amz-Algorithm", valid_600991
  var valid_600992 = header.getOrDefault("X-Amz-Signature")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "X-Amz-Signature", valid_600992
  var valid_600993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "X-Amz-SignedHeaders", valid_600993
  var valid_600994 = header.getOrDefault("X-Amz-Credential")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Credential", valid_600994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600995: Call_DisassociatePhoneNumberFromUser_600982;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_600995.validator(path, query, header, formData, body)
  let scheme = call_600995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600995.url(scheme.get, call_600995.host, call_600995.base,
                         call_600995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600995, url, valid)

proc call*(call_600996: Call_DisassociatePhoneNumberFromUser_600982;
          accountId: string; userId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_600997 = newJObject()
  var query_600998 = newJObject()
  add(path_600997, "accountId", newJString(accountId))
  add(query_600998, "operation", newJString(operation))
  add(path_600997, "userId", newJString(userId))
  result = call_600996.call(path_600997, query_600998, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_600982(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_600983, base: "/",
    url: url_DisassociatePhoneNumberFromUser_600984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_600999 = ref object of OpenApiRestCall_599368
proc url_DisassociatePhoneNumbersFromVoiceConnector_601001(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnector_601000(path: JsonNode;
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
  var valid_601002 = path.getOrDefault("voiceConnectorId")
  valid_601002 = validateParameter(valid_601002, JString, required = true,
                                 default = nil)
  if valid_601002 != nil:
    section.add "voiceConnectorId", valid_601002
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601003 = query.getOrDefault("operation")
  valid_601003 = validateParameter(valid_601003, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_601003 != nil:
    section.add "operation", valid_601003
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
  var valid_601004 = header.getOrDefault("X-Amz-Date")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "X-Amz-Date", valid_601004
  var valid_601005 = header.getOrDefault("X-Amz-Security-Token")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "X-Amz-Security-Token", valid_601005
  var valid_601006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "X-Amz-Content-Sha256", valid_601006
  var valid_601007 = header.getOrDefault("X-Amz-Algorithm")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Algorithm", valid_601007
  var valid_601008 = header.getOrDefault("X-Amz-Signature")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "X-Amz-Signature", valid_601008
  var valid_601009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-SignedHeaders", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Credential")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Credential", valid_601010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601012: Call_DisassociatePhoneNumbersFromVoiceConnector_600999;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601012.validator(path, query, header, formData, body)
  let scheme = call_601012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601012.url(scheme.get, call_601012.host, call_601012.base,
                         call_601012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601012, url, valid)

proc call*(call_601013: Call_DisassociatePhoneNumbersFromVoiceConnector_600999;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601014 = newJObject()
  var query_601015 = newJObject()
  var body_601016 = newJObject()
  add(path_601014, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_601015, "operation", newJString(operation))
  if body != nil:
    body_601016 = body
  result = call_601013.call(path_601014, query_601015, nil, nil, body_601016)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_600999(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_601000,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_601001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_601017 = ref object of OpenApiRestCall_599368
proc url_DisassociatePhoneNumbersFromVoiceConnectorGroup_601019(protocol: Scheme;
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

proc validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_601018(
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
  var valid_601020 = path.getOrDefault("voiceConnectorGroupId")
  valid_601020 = validateParameter(valid_601020, JString, required = true,
                                 default = nil)
  if valid_601020 != nil:
    section.add "voiceConnectorGroupId", valid_601020
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601021 = query.getOrDefault("operation")
  valid_601021 = validateParameter(valid_601021, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_601021 != nil:
    section.add "operation", valid_601021
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
  var valid_601022 = header.getOrDefault("X-Amz-Date")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "X-Amz-Date", valid_601022
  var valid_601023 = header.getOrDefault("X-Amz-Security-Token")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "X-Amz-Security-Token", valid_601023
  var valid_601024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Content-Sha256", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-Algorithm")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Algorithm", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Signature")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Signature", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-SignedHeaders", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Credential")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Credential", valid_601028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601030: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_601017;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ## 
  let valid = call_601030.validator(path, query, header, formData, body)
  let scheme = call_601030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601030.url(scheme.get, call_601030.host, call_601030.base,
                         call_601030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601030, url, valid)

proc call*(call_601031: Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_601017;
          voiceConnectorGroupId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnectorGroup
  ## Disassociates the specified phone numbers from the specified Amazon Chime Voice Connector group.
  ##   voiceConnectorGroupId: string (required)
  ##                        : The Amazon Chime Voice Connector group ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601032 = newJObject()
  var query_601033 = newJObject()
  var body_601034 = newJObject()
  add(path_601032, "voiceConnectorGroupId", newJString(voiceConnectorGroupId))
  add(query_601033, "operation", newJString(operation))
  if body != nil:
    body_601034 = body
  result = call_601031.call(path_601032, query_601033, nil, nil, body_601034)

var disassociatePhoneNumbersFromVoiceConnectorGroup* = Call_DisassociatePhoneNumbersFromVoiceConnectorGroup_601017(
    name: "disassociatePhoneNumbersFromVoiceConnectorGroup",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/voice-connector-groups/{voiceConnectorGroupId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnectorGroup_601018,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnectorGroup_601019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_601049 = ref object of OpenApiRestCall_599368
proc url_UpdateAccountSettings_601051(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAccountSettings_601050(path: JsonNode; query: JsonNode;
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
  var valid_601052 = path.getOrDefault("accountId")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = nil)
  if valid_601052 != nil:
    section.add "accountId", valid_601052
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
  var valid_601053 = header.getOrDefault("X-Amz-Date")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Date", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Security-Token")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Security-Token", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Content-Sha256", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Algorithm")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Algorithm", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Signature")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Signature", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-SignedHeaders", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Credential")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Credential", valid_601059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601061: Call_UpdateAccountSettings_601049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_601061.validator(path, query, header, formData, body)
  let scheme = call_601061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601061.url(scheme.get, call_601061.host, call_601061.base,
                         call_601061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601061, url, valid)

proc call*(call_601062: Call_UpdateAccountSettings_601049; accountId: string;
          body: JsonNode): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_601063 = newJObject()
  var body_601064 = newJObject()
  add(path_601063, "accountId", newJString(accountId))
  if body != nil:
    body_601064 = body
  result = call_601062.call(path_601063, nil, nil, nil, body_601064)

var updateAccountSettings* = Call_UpdateAccountSettings_601049(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_601050, base: "/",
    url: url_UpdateAccountSettings_601051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_601035 = ref object of OpenApiRestCall_599368
proc url_GetAccountSettings_601037(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_601036(path: JsonNode; query: JsonNode;
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
  var valid_601038 = path.getOrDefault("accountId")
  valid_601038 = validateParameter(valid_601038, JString, required = true,
                                 default = nil)
  if valid_601038 != nil:
    section.add "accountId", valid_601038
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
  var valid_601039 = header.getOrDefault("X-Amz-Date")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Date", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Security-Token")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Security-Token", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Content-Sha256", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Algorithm")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Algorithm", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Signature")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Signature", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-SignedHeaders", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Credential")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Credential", valid_601045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601046: Call_GetAccountSettings_601035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_601046.validator(path, query, header, formData, body)
  let scheme = call_601046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601046.url(scheme.get, call_601046.host, call_601046.base,
                         call_601046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601046, url, valid)

proc call*(call_601047: Call_GetAccountSettings_601035; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_601048 = newJObject()
  add(path_601048, "accountId", newJString(accountId))
  result = call_601047.call(path_601048, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_601035(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_601036, base: "/",
    url: url_GetAccountSettings_601037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_601080 = ref object of OpenApiRestCall_599368
proc url_UpdateBot_601082(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateBot_601081(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601083 = path.getOrDefault("accountId")
  valid_601083 = validateParameter(valid_601083, JString, required = true,
                                 default = nil)
  if valid_601083 != nil:
    section.add "accountId", valid_601083
  var valid_601084 = path.getOrDefault("botId")
  valid_601084 = validateParameter(valid_601084, JString, required = true,
                                 default = nil)
  if valid_601084 != nil:
    section.add "botId", valid_601084
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
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Content-Sha256", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Algorithm")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Algorithm", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Signature")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Signature", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-SignedHeaders", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Credential")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Credential", valid_601091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601093: Call_UpdateBot_601080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_601093.validator(path, query, header, formData, body)
  let scheme = call_601093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601093.url(scheme.get, call_601093.host, call_601093.base,
                         call_601093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601093, url, valid)

proc call*(call_601094: Call_UpdateBot_601080; accountId: string; botId: string;
          body: JsonNode): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_601095 = newJObject()
  var body_601096 = newJObject()
  add(path_601095, "accountId", newJString(accountId))
  add(path_601095, "botId", newJString(botId))
  if body != nil:
    body_601096 = body
  result = call_601094.call(path_601095, nil, nil, nil, body_601096)

var updateBot* = Call_UpdateBot_601080(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_601081,
                                    base: "/", url: url_UpdateBot_601082,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_601065 = ref object of OpenApiRestCall_599368
proc url_GetBot_601067(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_601066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601068 = path.getOrDefault("accountId")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = nil)
  if valid_601068 != nil:
    section.add "accountId", valid_601068
  var valid_601069 = path.getOrDefault("botId")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = nil)
  if valid_601069 != nil:
    section.add "botId", valid_601069
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
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Content-Sha256", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Algorithm")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Algorithm", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Signature")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Signature", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-SignedHeaders", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Credential")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Credential", valid_601076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601077: Call_GetBot_601065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_601077.validator(path, query, header, formData, body)
  let scheme = call_601077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601077.url(scheme.get, call_601077.host, call_601077.base,
                         call_601077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601077, url, valid)

proc call*(call_601078: Call_GetBot_601065; accountId: string; botId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_601079 = newJObject()
  add(path_601079, "accountId", newJString(accountId))
  add(path_601079, "botId", newJString(botId))
  result = call_601078.call(path_601079, nil, nil, nil, nil)

var getBot* = Call_GetBot_601065(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_601066, base: "/",
                              url: url_GetBot_601067,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_601109 = ref object of OpenApiRestCall_599368
proc url_UpdateGlobalSettings_601111(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGlobalSettings_601110(path: JsonNode; query: JsonNode;
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
  var valid_601112 = header.getOrDefault("X-Amz-Date")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Date", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Security-Token")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Security-Token", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Content-Sha256", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Algorithm")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Algorithm", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Signature")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Signature", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-SignedHeaders", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Credential")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Credential", valid_601118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601120: Call_UpdateGlobalSettings_601109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_601120.validator(path, query, header, formData, body)
  let scheme = call_601120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601120.url(scheme.get, call_601120.host, call_601120.base,
                         call_601120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601120, url, valid)

proc call*(call_601121: Call_UpdateGlobalSettings_601109; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_601122 = newJObject()
  if body != nil:
    body_601122 = body
  result = call_601121.call(nil, nil, nil, nil, body_601122)

var updateGlobalSettings* = Call_UpdateGlobalSettings_601109(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_601110, base: "/",
    url: url_UpdateGlobalSettings_601111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_601097 = ref object of OpenApiRestCall_599368
proc url_GetGlobalSettings_601099(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGlobalSettings_601098(path: JsonNode; query: JsonNode;
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
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Content-Sha256", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Algorithm")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Algorithm", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Signature")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Signature", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-SignedHeaders", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Credential")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Credential", valid_601106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601107: Call_GetGlobalSettings_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_601107.validator(path, query, header, formData, body)
  let scheme = call_601107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601107.url(scheme.get, call_601107.host, call_601107.base,
                         call_601107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601107, url, valid)

proc call*(call_601108: Call_GetGlobalSettings_601097): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_601108.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_601097(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_601098, base: "/",
    url: url_GetGlobalSettings_601099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_601123 = ref object of OpenApiRestCall_599368
proc url_GetPhoneNumberOrder_601125(protocol: Scheme; host: string; base: string;
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

proc validate_GetPhoneNumberOrder_601124(path: JsonNode; query: JsonNode;
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
  var valid_601126 = path.getOrDefault("phoneNumberOrderId")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = nil)
  if valid_601126 != nil:
    section.add "phoneNumberOrderId", valid_601126
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
  var valid_601127 = header.getOrDefault("X-Amz-Date")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Date", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Security-Token")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Security-Token", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Content-Sha256", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Algorithm")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Algorithm", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Signature")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Signature", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-SignedHeaders", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Credential")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Credential", valid_601133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601134: Call_GetPhoneNumberOrder_601123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_601134.validator(path, query, header, formData, body)
  let scheme = call_601134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601134.url(scheme.get, call_601134.host, call_601134.base,
                         call_601134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601134, url, valid)

proc call*(call_601135: Call_GetPhoneNumberOrder_601123; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_601136 = newJObject()
  add(path_601136, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_601135.call(path_601136, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_601123(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_601124, base: "/",
    url: url_GetPhoneNumberOrder_601125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumberSettings_601149 = ref object of OpenApiRestCall_599368
proc url_UpdatePhoneNumberSettings_601151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePhoneNumberSettings_601150(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_UpdatePhoneNumberSettings_601149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601160, url, valid)

proc call*(call_601161: Call_UpdatePhoneNumberSettings_601149; body: JsonNode): Recallable =
  ## updatePhoneNumberSettings
  ## Updates the phone number settings for the administrator's AWS account, such as the default outbound calling name. You can update the default outbound calling name once every seven days. Outbound calling names can take up to 72 hours to update.
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var updatePhoneNumberSettings* = Call_UpdatePhoneNumberSettings_601149(
    name: "updatePhoneNumberSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_UpdatePhoneNumberSettings_601150, base: "/",
    url: url_UpdatePhoneNumberSettings_601151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberSettings_601137 = ref object of OpenApiRestCall_599368
proc url_GetPhoneNumberSettings_601139(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPhoneNumberSettings_601138(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601140 = header.getOrDefault("X-Amz-Date")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Date", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Security-Token")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Security-Token", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Content-Sha256", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Algorithm")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Algorithm", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Signature")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Signature", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-SignedHeaders", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Credential")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Credential", valid_601146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601147: Call_GetPhoneNumberSettings_601137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  ## 
  let valid = call_601147.validator(path, query, header, formData, body)
  let scheme = call_601147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601147.url(scheme.get, call_601147.host, call_601147.base,
                         call_601147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601147, url, valid)

proc call*(call_601148: Call_GetPhoneNumberSettings_601137): Recallable =
  ## getPhoneNumberSettings
  ## Retrieves the phone number settings for the administrator's AWS account, such as the default outbound calling name.
  result = call_601148.call(nil, nil, nil, nil, nil)

var getPhoneNumberSettings* = Call_GetPhoneNumberSettings_601137(
    name: "getPhoneNumberSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/settings/phone-number",
    validator: validate_GetPhoneNumberSettings_601138, base: "/",
    url: url_GetPhoneNumberSettings_601139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_601178 = ref object of OpenApiRestCall_599368
proc url_UpdateUser_601180(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_601179(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601181 = path.getOrDefault("accountId")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = nil)
  if valid_601181 != nil:
    section.add "accountId", valid_601181
  var valid_601182 = path.getOrDefault("userId")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = nil)
  if valid_601182 != nil:
    section.add "userId", valid_601182
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
  var valid_601183 = header.getOrDefault("X-Amz-Date")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Date", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Security-Token")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Security-Token", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Content-Sha256", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Algorithm")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Algorithm", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Signature")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Signature", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-SignedHeaders", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Credential")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Credential", valid_601189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_UpdateUser_601178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601191, url, valid)

proc call*(call_601192: Call_UpdateUser_601178; accountId: string; body: JsonNode;
          userId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601193 = newJObject()
  var body_601194 = newJObject()
  add(path_601193, "accountId", newJString(accountId))
  if body != nil:
    body_601194 = body
  add(path_601193, "userId", newJString(userId))
  result = call_601192.call(path_601193, nil, nil, nil, body_601194)

var updateUser* = Call_UpdateUser_601178(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_601179,
                                      base: "/", url: url_UpdateUser_601180,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_601163 = ref object of OpenApiRestCall_599368
proc url_GetUser_601165(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetUser_601164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601166 = path.getOrDefault("accountId")
  valid_601166 = validateParameter(valid_601166, JString, required = true,
                                 default = nil)
  if valid_601166 != nil:
    section.add "accountId", valid_601166
  var valid_601167 = path.getOrDefault("userId")
  valid_601167 = validateParameter(valid_601167, JString, required = true,
                                 default = nil)
  if valid_601167 != nil:
    section.add "userId", valid_601167
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
  var valid_601168 = header.getOrDefault("X-Amz-Date")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Date", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Security-Token")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Security-Token", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Content-Sha256", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Algorithm")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Algorithm", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Signature")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Signature", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-SignedHeaders", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Credential")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Credential", valid_601174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_GetUser_601163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601175, url, valid)

proc call*(call_601176: Call_GetUser_601163; accountId: string; userId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_601177 = newJObject()
  add(path_601177, "accountId", newJString(accountId))
  add(path_601177, "userId", newJString(userId))
  result = call_601176.call(path_601177, nil, nil, nil, nil)

var getUser* = Call_GetUser_601163(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_601164, base: "/",
                                url: url_GetUser_601165,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_601210 = ref object of OpenApiRestCall_599368
proc url_UpdateUserSettings_601212(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserSettings_601211(path: JsonNode; query: JsonNode;
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
  var valid_601213 = path.getOrDefault("accountId")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = nil)
  if valid_601213 != nil:
    section.add "accountId", valid_601213
  var valid_601214 = path.getOrDefault("userId")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = nil)
  if valid_601214 != nil:
    section.add "userId", valid_601214
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
  var valid_601215 = header.getOrDefault("X-Amz-Date")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Date", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Security-Token")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Security-Token", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Content-Sha256", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Algorithm")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Algorithm", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Signature")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Signature", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-SignedHeaders", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Credential")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Credential", valid_601221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601223: Call_UpdateUserSettings_601210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_601223.validator(path, query, header, formData, body)
  let scheme = call_601223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601223.url(scheme.get, call_601223.host, call_601223.base,
                         call_601223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601223, url, valid)

proc call*(call_601224: Call_UpdateUserSettings_601210; accountId: string;
          body: JsonNode; userId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601225 = newJObject()
  var body_601226 = newJObject()
  add(path_601225, "accountId", newJString(accountId))
  if body != nil:
    body_601226 = body
  add(path_601225, "userId", newJString(userId))
  result = call_601224.call(path_601225, nil, nil, nil, body_601226)

var updateUserSettings* = Call_UpdateUserSettings_601210(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_601211, base: "/",
    url: url_UpdateUserSettings_601212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_601195 = ref object of OpenApiRestCall_599368
proc url_GetUserSettings_601197(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserSettings_601196(path: JsonNode; query: JsonNode;
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
  var valid_601198 = path.getOrDefault("accountId")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = nil)
  if valid_601198 != nil:
    section.add "accountId", valid_601198
  var valid_601199 = path.getOrDefault("userId")
  valid_601199 = validateParameter(valid_601199, JString, required = true,
                                 default = nil)
  if valid_601199 != nil:
    section.add "userId", valid_601199
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
  var valid_601200 = header.getOrDefault("X-Amz-Date")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Date", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Security-Token")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Security-Token", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Content-Sha256", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Algorithm")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Algorithm", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Signature")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Signature", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-SignedHeaders", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Credential")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Credential", valid_601206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601207: Call_GetUserSettings_601195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_601207.validator(path, query, header, formData, body)
  let scheme = call_601207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601207.url(scheme.get, call_601207.host, call_601207.base,
                         call_601207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601207, url, valid)

proc call*(call_601208: Call_GetUserSettings_601195; accountId: string;
          userId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_601209 = newJObject()
  add(path_601209, "accountId", newJString(accountId))
  add(path_601209, "userId", newJString(userId))
  result = call_601208.call(path_601209, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_601195(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_601196, base: "/", url: url_GetUserSettings_601197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorLoggingConfiguration_601241 = ref object of OpenApiRestCall_599368
proc url_PutVoiceConnectorLoggingConfiguration_601243(protocol: Scheme;
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

proc validate_PutVoiceConnectorLoggingConfiguration_601242(path: JsonNode;
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
  var valid_601244 = path.getOrDefault("voiceConnectorId")
  valid_601244 = validateParameter(valid_601244, JString, required = true,
                                 default = nil)
  if valid_601244 != nil:
    section.add "voiceConnectorId", valid_601244
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
  var valid_601245 = header.getOrDefault("X-Amz-Date")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Date", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Security-Token")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Security-Token", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Content-Sha256", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Algorithm")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Algorithm", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Signature")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Signature", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-SignedHeaders", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Credential")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Credential", valid_601251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601253: Call_PutVoiceConnectorLoggingConfiguration_601241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_601253.validator(path, query, header, formData, body)
  let scheme = call_601253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601253.url(scheme.get, call_601253.host, call_601253.base,
                         call_601253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601253, url, valid)

proc call*(call_601254: Call_PutVoiceConnectorLoggingConfiguration_601241;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorLoggingConfiguration
  ## Adds a logging configuration for the specified Amazon Chime Voice Connector. The logging configuration specifies whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_601255 = newJObject()
  var body_601256 = newJObject()
  add(path_601255, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_601256 = body
  result = call_601254.call(path_601255, nil, nil, nil, body_601256)

var putVoiceConnectorLoggingConfiguration* = Call_PutVoiceConnectorLoggingConfiguration_601241(
    name: "putVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_PutVoiceConnectorLoggingConfiguration_601242, base: "/",
    url: url_PutVoiceConnectorLoggingConfiguration_601243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorLoggingConfiguration_601227 = ref object of OpenApiRestCall_599368
proc url_GetVoiceConnectorLoggingConfiguration_601229(protocol: Scheme;
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

proc validate_GetVoiceConnectorLoggingConfiguration_601228(path: JsonNode;
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
  var valid_601230 = path.getOrDefault("voiceConnectorId")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = nil)
  if valid_601230 != nil:
    section.add "voiceConnectorId", valid_601230
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
  var valid_601231 = header.getOrDefault("X-Amz-Date")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Date", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Security-Token")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Security-Token", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601238: Call_GetVoiceConnectorLoggingConfiguration_601227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ## 
  let valid = call_601238.validator(path, query, header, formData, body)
  let scheme = call_601238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601238.url(scheme.get, call_601238.host, call_601238.base,
                         call_601238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601238, url, valid)

proc call*(call_601239: Call_GetVoiceConnectorLoggingConfiguration_601227;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorLoggingConfiguration
  ## Retrieves the logging configuration details for the specified Amazon Chime Voice Connector. Shows whether SIP message logs are enabled for sending to Amazon CloudWatch Logs.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601240 = newJObject()
  add(path_601240, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601239.call(path_601240, nil, nil, nil, nil)

var getVoiceConnectorLoggingConfiguration* = Call_GetVoiceConnectorLoggingConfiguration_601227(
    name: "getVoiceConnectorLoggingConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/logging-configuration",
    validator: validate_GetVoiceConnectorLoggingConfiguration_601228, base: "/",
    url: url_GetVoiceConnectorLoggingConfiguration_601229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_601257 = ref object of OpenApiRestCall_599368
proc url_GetVoiceConnectorTerminationHealth_601259(protocol: Scheme; host: string;
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

proc validate_GetVoiceConnectorTerminationHealth_601258(path: JsonNode;
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
  var valid_601260 = path.getOrDefault("voiceConnectorId")
  valid_601260 = validateParameter(valid_601260, JString, required = true,
                                 default = nil)
  if valid_601260 != nil:
    section.add "voiceConnectorId", valid_601260
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
  var valid_601261 = header.getOrDefault("X-Amz-Date")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Date", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Security-Token")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Security-Token", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Content-Sha256", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Algorithm")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Algorithm", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Signature")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Signature", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-SignedHeaders", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Credential")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Credential", valid_601267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601268: Call_GetVoiceConnectorTerminationHealth_601257;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601268.validator(path, query, header, formData, body)
  let scheme = call_601268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601268.url(scheme.get, call_601268.host, call_601268.base,
                         call_601268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601268, url, valid)

proc call*(call_601269: Call_GetVoiceConnectorTerminationHealth_601257;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601270 = newJObject()
  add(path_601270, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601269.call(path_601270, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_601257(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_601258, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_601259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_601271 = ref object of OpenApiRestCall_599368
proc url_InviteUsers_601273(protocol: Scheme; host: string; base: string;
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

proc validate_InviteUsers_601272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601274 = path.getOrDefault("accountId")
  valid_601274 = validateParameter(valid_601274, JString, required = true,
                                 default = nil)
  if valid_601274 != nil:
    section.add "accountId", valid_601274
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601275 = query.getOrDefault("operation")
  valid_601275 = validateParameter(valid_601275, JString, required = true,
                                 default = newJString("add"))
  if valid_601275 != nil:
    section.add "operation", valid_601275
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
  var valid_601276 = header.getOrDefault("X-Amz-Date")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Date", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Security-Token")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Security-Token", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Content-Sha256", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Algorithm")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Algorithm", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Signature")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Signature", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-SignedHeaders", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Credential")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Credential", valid_601282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601284: Call_InviteUsers_601271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_601284.validator(path, query, header, formData, body)
  let scheme = call_601284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601284.url(scheme.get, call_601284.host, call_601284.base,
                         call_601284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601284, url, valid)

proc call*(call_601285: Call_InviteUsers_601271; accountId: string; body: JsonNode;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email to a maximum of 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601286 = newJObject()
  var query_601287 = newJObject()
  var body_601288 = newJObject()
  add(path_601286, "accountId", newJString(accountId))
  add(query_601287, "operation", newJString(operation))
  if body != nil:
    body_601288 = body
  result = call_601285.call(path_601286, query_601287, nil, nil, body_601288)

var inviteUsers* = Call_InviteUsers_601271(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_601272,
                                        base: "/", url: url_InviteUsers_601273,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_601289 = ref object of OpenApiRestCall_599368
proc url_ListPhoneNumbers_601291(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPhoneNumbers_601290(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_601292 = query.getOrDefault("filter-name")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_601292 != nil:
    section.add "filter-name", valid_601292
  var valid_601293 = query.getOrDefault("NextToken")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "NextToken", valid_601293
  var valid_601294 = query.getOrDefault("max-results")
  valid_601294 = validateParameter(valid_601294, JInt, required = false, default = nil)
  if valid_601294 != nil:
    section.add "max-results", valid_601294
  var valid_601295 = query.getOrDefault("filter-value")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "filter-value", valid_601295
  var valid_601296 = query.getOrDefault("status")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_601296 != nil:
    section.add "status", valid_601296
  var valid_601297 = query.getOrDefault("product-type")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_601297 != nil:
    section.add "product-type", valid_601297
  var valid_601298 = query.getOrDefault("next-token")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "next-token", valid_601298
  var valid_601299 = query.getOrDefault("MaxResults")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "MaxResults", valid_601299
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
  var valid_601300 = header.getOrDefault("X-Amz-Date")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Date", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Security-Token")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Security-Token", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Content-Sha256", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Algorithm")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Algorithm", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Signature")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Signature", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-SignedHeaders", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Credential")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Credential", valid_601306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601307: Call_ListPhoneNumbers_601289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, Amazon Chime Voice Connector, or Amazon Chime Voice Connector group.
  ## 
  let valid = call_601307.validator(path, query, header, formData, body)
  let scheme = call_601307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601307.url(scheme.get, call_601307.host, call_601307.base,
                         call_601307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601307, url, valid)

proc call*(call_601308: Call_ListPhoneNumbers_601289;
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
  var query_601309 = newJObject()
  add(query_601309, "filter-name", newJString(filterName))
  add(query_601309, "NextToken", newJString(NextToken))
  add(query_601309, "max-results", newJInt(maxResults))
  add(query_601309, "filter-value", newJString(filterValue))
  add(query_601309, "status", newJString(status))
  add(query_601309, "product-type", newJString(productType))
  add(query_601309, "next-token", newJString(nextToken))
  add(query_601309, "MaxResults", newJString(MaxResults))
  result = call_601308.call(nil, query_601309, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_601289(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_601290, base: "/",
    url: url_ListPhoneNumbers_601291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_601310 = ref object of OpenApiRestCall_599368
proc url_ListVoiceConnectorTerminationCredentials_601312(protocol: Scheme;
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

proc validate_ListVoiceConnectorTerminationCredentials_601311(path: JsonNode;
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
  var valid_601313 = path.getOrDefault("voiceConnectorId")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "voiceConnectorId", valid_601313
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
  var valid_601314 = header.getOrDefault("X-Amz-Date")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Date", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Security-Token")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Security-Token", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Content-Sha256", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Algorithm")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Algorithm", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Signature")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Signature", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-SignedHeaders", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Credential")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Credential", valid_601320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601321: Call_ListVoiceConnectorTerminationCredentials_601310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601321.validator(path, query, header, formData, body)
  let scheme = call_601321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601321.url(scheme.get, call_601321.host, call_601321.base,
                         call_601321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601321, url, valid)

proc call*(call_601322: Call_ListVoiceConnectorTerminationCredentials_601310;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601323 = newJObject()
  add(path_601323, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601322.call(path_601323, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_601310(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_601311,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_601312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_601324 = ref object of OpenApiRestCall_599368
proc url_LogoutUser_601326(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_LogoutUser_601325(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601327 = path.getOrDefault("accountId")
  valid_601327 = validateParameter(valid_601327, JString, required = true,
                                 default = nil)
  if valid_601327 != nil:
    section.add "accountId", valid_601327
  var valid_601328 = path.getOrDefault("userId")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "userId", valid_601328
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601329 = query.getOrDefault("operation")
  valid_601329 = validateParameter(valid_601329, JString, required = true,
                                 default = newJString("logout"))
  if valid_601329 != nil:
    section.add "operation", valid_601329
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
  var valid_601330 = header.getOrDefault("X-Amz-Date")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Date", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Security-Token")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Security-Token", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Content-Sha256", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Algorithm")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Algorithm", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Signature")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Signature", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-SignedHeaders", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Credential")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Credential", valid_601336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601337: Call_LogoutUser_601324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_601337.validator(path, query, header, formData, body)
  let scheme = call_601337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601337.url(scheme.get, call_601337.host, call_601337.base,
                         call_601337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601337, url, valid)

proc call*(call_601338: Call_LogoutUser_601324; accountId: string; userId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601339 = newJObject()
  var query_601340 = newJObject()
  add(path_601339, "accountId", newJString(accountId))
  add(query_601340, "operation", newJString(operation))
  add(path_601339, "userId", newJString(userId))
  result = call_601338.call(path_601339, query_601340, nil, nil, nil)

var logoutUser* = Call_LogoutUser_601324(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_601325,
                                      base: "/", url: url_LogoutUser_601326,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_601341 = ref object of OpenApiRestCall_599368
proc url_PutVoiceConnectorTerminationCredentials_601343(protocol: Scheme;
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

proc validate_PutVoiceConnectorTerminationCredentials_601342(path: JsonNode;
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
  var valid_601344 = path.getOrDefault("voiceConnectorId")
  valid_601344 = validateParameter(valid_601344, JString, required = true,
                                 default = nil)
  if valid_601344 != nil:
    section.add "voiceConnectorId", valid_601344
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601345 = query.getOrDefault("operation")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = newJString("put"))
  if valid_601345 != nil:
    section.add "operation", valid_601345
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
  var valid_601346 = header.getOrDefault("X-Amz-Date")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Date", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Security-Token")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Security-Token", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Content-Sha256", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Algorithm")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Algorithm", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Signature")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Signature", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-SignedHeaders", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Credential")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Credential", valid_601352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601354: Call_PutVoiceConnectorTerminationCredentials_601341;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601354.validator(path, query, header, formData, body)
  let scheme = call_601354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601354.url(scheme.get, call_601354.host, call_601354.base,
                         call_601354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601354, url, valid)

proc call*(call_601355: Call_PutVoiceConnectorTerminationCredentials_601341;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601356 = newJObject()
  var query_601357 = newJObject()
  var body_601358 = newJObject()
  add(path_601356, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_601357, "operation", newJString(operation))
  if body != nil:
    body_601358 = body
  result = call_601355.call(path_601356, query_601357, nil, nil, body_601358)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_601341(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_601342, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_601343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_601359 = ref object of OpenApiRestCall_599368
proc url_RegenerateSecurityToken_601361(protocol: Scheme; host: string; base: string;
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

proc validate_RegenerateSecurityToken_601360(path: JsonNode; query: JsonNode;
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
  var valid_601362 = path.getOrDefault("accountId")
  valid_601362 = validateParameter(valid_601362, JString, required = true,
                                 default = nil)
  if valid_601362 != nil:
    section.add "accountId", valid_601362
  var valid_601363 = path.getOrDefault("botId")
  valid_601363 = validateParameter(valid_601363, JString, required = true,
                                 default = nil)
  if valid_601363 != nil:
    section.add "botId", valid_601363
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601364 = query.getOrDefault("operation")
  valid_601364 = validateParameter(valid_601364, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_601364 != nil:
    section.add "operation", valid_601364
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
  var valid_601365 = header.getOrDefault("X-Amz-Date")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Date", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Security-Token")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Security-Token", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Content-Sha256", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Algorithm")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Algorithm", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Signature")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Signature", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-SignedHeaders", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Credential")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Credential", valid_601371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601372: Call_RegenerateSecurityToken_601359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_601372.validator(path, query, header, formData, body)
  let scheme = call_601372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601372.url(scheme.get, call_601372.host, call_601372.base,
                         call_601372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601372, url, valid)

proc call*(call_601373: Call_RegenerateSecurityToken_601359; accountId: string;
          botId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  var path_601374 = newJObject()
  var query_601375 = newJObject()
  add(path_601374, "accountId", newJString(accountId))
  add(path_601374, "botId", newJString(botId))
  add(query_601375, "operation", newJString(operation))
  result = call_601373.call(path_601374, query_601375, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_601359(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_601360, base: "/",
    url: url_RegenerateSecurityToken_601361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_601376 = ref object of OpenApiRestCall_599368
proc url_ResetPersonalPIN_601378(protocol: Scheme; host: string; base: string;
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

proc validate_ResetPersonalPIN_601377(path: JsonNode; query: JsonNode;
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
  var valid_601379 = path.getOrDefault("accountId")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = nil)
  if valid_601379 != nil:
    section.add "accountId", valid_601379
  var valid_601380 = path.getOrDefault("userId")
  valid_601380 = validateParameter(valid_601380, JString, required = true,
                                 default = nil)
  if valid_601380 != nil:
    section.add "userId", valid_601380
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601381 = query.getOrDefault("operation")
  valid_601381 = validateParameter(valid_601381, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_601381 != nil:
    section.add "operation", valid_601381
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
  var valid_601382 = header.getOrDefault("X-Amz-Date")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Date", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Security-Token")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Security-Token", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Content-Sha256", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Algorithm")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Algorithm", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Signature")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Signature", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-SignedHeaders", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Credential")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Credential", valid_601388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601389: Call_ResetPersonalPIN_601376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_601389.validator(path, query, header, formData, body)
  let scheme = call_601389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601389.url(scheme.get, call_601389.host, call_601389.base,
                         call_601389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601389, url, valid)

proc call*(call_601390: Call_ResetPersonalPIN_601376; accountId: string;
          userId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601391 = newJObject()
  var query_601392 = newJObject()
  add(path_601391, "accountId", newJString(accountId))
  add(query_601392, "operation", newJString(operation))
  add(path_601391, "userId", newJString(userId))
  result = call_601390.call(path_601391, query_601392, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_601376(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_601377, base: "/",
    url: url_ResetPersonalPIN_601378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_601393 = ref object of OpenApiRestCall_599368
proc url_RestorePhoneNumber_601395(protocol: Scheme; host: string; base: string;
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

proc validate_RestorePhoneNumber_601394(path: JsonNode; query: JsonNode;
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
  var valid_601396 = path.getOrDefault("phoneNumberId")
  valid_601396 = validateParameter(valid_601396, JString, required = true,
                                 default = nil)
  if valid_601396 != nil:
    section.add "phoneNumberId", valid_601396
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601397 = query.getOrDefault("operation")
  valid_601397 = validateParameter(valid_601397, JString, required = true,
                                 default = newJString("restore"))
  if valid_601397 != nil:
    section.add "operation", valid_601397
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
  var valid_601398 = header.getOrDefault("X-Amz-Date")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Date", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Security-Token")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Security-Token", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Content-Sha256", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Algorithm")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Algorithm", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Signature")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Signature", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-SignedHeaders", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Credential")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Credential", valid_601404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601405: Call_RestorePhoneNumber_601393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_601405.validator(path, query, header, formData, body)
  let scheme = call_601405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601405.url(scheme.get, call_601405.host, call_601405.base,
                         call_601405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601405, url, valid)

proc call*(call_601406: Call_RestorePhoneNumber_601393; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_601407 = newJObject()
  var query_601408 = newJObject()
  add(path_601407, "phoneNumberId", newJString(phoneNumberId))
  add(query_601408, "operation", newJString(operation))
  result = call_601406.call(path_601407, query_601408, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_601393(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_601394, base: "/",
    url: url_RestorePhoneNumber_601395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_601409 = ref object of OpenApiRestCall_599368
proc url_SearchAvailablePhoneNumbers_601411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchAvailablePhoneNumbers_601410(path: JsonNode; query: JsonNode;
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
  var valid_601412 = query.getOrDefault("city")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "city", valid_601412
  var valid_601413 = query.getOrDefault("toll-free-prefix")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "toll-free-prefix", valid_601413
  var valid_601414 = query.getOrDefault("country")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "country", valid_601414
  var valid_601415 = query.getOrDefault("area-code")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "area-code", valid_601415
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_601416 = query.getOrDefault("type")
  valid_601416 = validateParameter(valid_601416, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_601416 != nil:
    section.add "type", valid_601416
  var valid_601417 = query.getOrDefault("max-results")
  valid_601417 = validateParameter(valid_601417, JInt, required = false, default = nil)
  if valid_601417 != nil:
    section.add "max-results", valid_601417
  var valid_601418 = query.getOrDefault("next-token")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "next-token", valid_601418
  var valid_601419 = query.getOrDefault("state")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "state", valid_601419
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
  var valid_601420 = header.getOrDefault("X-Amz-Date")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Date", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Security-Token")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Security-Token", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Content-Sha256", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Algorithm")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Algorithm", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Signature")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Signature", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-SignedHeaders", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Credential")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Credential", valid_601426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601427: Call_SearchAvailablePhoneNumbers_601409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_601427.validator(path, query, header, formData, body)
  let scheme = call_601427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601427.url(scheme.get, call_601427.host, call_601427.base,
                         call_601427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601427, url, valid)

proc call*(call_601428: Call_SearchAvailablePhoneNumbers_601409; city: string = "";
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
  var query_601429 = newJObject()
  add(query_601429, "city", newJString(city))
  add(query_601429, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_601429, "country", newJString(country))
  add(query_601429, "area-code", newJString(areaCode))
  add(query_601429, "type", newJString(`type`))
  add(query_601429, "max-results", newJInt(maxResults))
  add(query_601429, "next-token", newJString(nextToken))
  add(query_601429, "state", newJString(state))
  result = call_601428.call(nil, query_601429, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_601409(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_601410, base: "/",
    url: url_SearchAvailablePhoneNumbers_601411,
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
