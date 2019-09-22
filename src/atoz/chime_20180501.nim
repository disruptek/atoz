
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociatePhoneNumberWithUser_602770 = ref object of OpenApiRestCall_602433
proc url_AssociatePhoneNumberWithUser_602772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_AssociatePhoneNumberWithUser_602771(path: JsonNode; query: JsonNode;
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
  var valid_602898 = path.getOrDefault("accountId")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "accountId", valid_602898
  var valid_602899 = path.getOrDefault("userId")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = nil)
  if valid_602899 != nil:
    section.add "userId", valid_602899
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_602913 = query.getOrDefault("operation")
  valid_602913 = validateParameter(valid_602913, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_602913 != nil:
    section.add "operation", valid_602913
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
  var valid_602914 = header.getOrDefault("X-Amz-Date")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Date", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Security-Token")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Security-Token", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Content-Sha256", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Algorithm")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Algorithm", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Signature")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Signature", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-SignedHeaders", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Credential")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Credential", valid_602920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602944: Call_AssociatePhoneNumberWithUser_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_602944.validator(path, query, header, formData, body)
  let scheme = call_602944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602944.url(scheme.get, call_602944.host, call_602944.base,
                         call_602944.route, valid.getOrDefault("path"))
  result = hook(call_602944, url, valid)

proc call*(call_603015: Call_AssociatePhoneNumberWithUser_602770;
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
  var path_603016 = newJObject()
  var query_603018 = newJObject()
  var body_603019 = newJObject()
  add(path_603016, "accountId", newJString(accountId))
  add(query_603018, "operation", newJString(operation))
  if body != nil:
    body_603019 = body
  add(path_603016, "userId", newJString(userId))
  result = call_603015.call(path_603016, query_603018, nil, nil, body_603019)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_602770(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_602771, base: "/",
    url: url_AssociatePhoneNumberWithUser_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_603058 = ref object of OpenApiRestCall_602433
proc url_AssociatePhoneNumbersWithVoiceConnector_603060(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_AssociatePhoneNumbersWithVoiceConnector_603059(path: JsonNode;
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
  var valid_603061 = path.getOrDefault("voiceConnectorId")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = nil)
  if valid_603061 != nil:
    section.add "voiceConnectorId", valid_603061
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603062 = query.getOrDefault("operation")
  valid_603062 = validateParameter(valid_603062, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_603062 != nil:
    section.add "operation", valid_603062
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
  var valid_603063 = header.getOrDefault("X-Amz-Date")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Date", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Security-Token")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Security-Token", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Content-Sha256", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Algorithm")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Algorithm", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Signature")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Signature", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-SignedHeaders", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Credential")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Credential", valid_603069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_AssociatePhoneNumbersWithVoiceConnector_603058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"))
  result = hook(call_603071, url, valid)

proc call*(call_603072: Call_AssociatePhoneNumbersWithVoiceConnector_603058;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603073 = newJObject()
  var query_603074 = newJObject()
  var body_603075 = newJObject()
  add(path_603073, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603074, "operation", newJString(operation))
  if body != nil:
    body_603075 = body
  result = call_603072.call(path_603073, query_603074, nil, nil, body_603075)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_603058(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_603059, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_603060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_603076 = ref object of OpenApiRestCall_602433
proc url_BatchDeletePhoneNumber_603078(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeletePhoneNumber_603077(path: JsonNode; query: JsonNode;
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
  var valid_603079 = query.getOrDefault("operation")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_603079 != nil:
    section.add "operation", valid_603079
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
  var valid_603080 = header.getOrDefault("X-Amz-Date")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Date", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Security-Token")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Security-Token", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Content-Sha256", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Algorithm")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Algorithm", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Signature")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Signature", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-SignedHeaders", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Credential")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Credential", valid_603086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_BatchDeletePhoneNumber_603076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"))
  result = hook(call_603088, url, valid)

proc call*(call_603089: Call_BatchDeletePhoneNumber_603076; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_603090 = newJObject()
  var body_603091 = newJObject()
  add(query_603090, "operation", newJString(operation))
  if body != nil:
    body_603091 = body
  result = call_603089.call(nil, query_603090, nil, nil, body_603091)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_603076(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_603077, base: "/",
    url: url_BatchDeletePhoneNumber_603078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_603092 = ref object of OpenApiRestCall_602433
proc url_BatchSuspendUser_603094(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users#operation=suspend")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_BatchSuspendUser_603093(path: JsonNode; query: JsonNode;
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
  var valid_603095 = path.getOrDefault("accountId")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "accountId", valid_603095
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603096 = query.getOrDefault("operation")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = newJString("suspend"))
  if valid_603096 != nil:
    section.add "operation", valid_603096
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
  var valid_603097 = header.getOrDefault("X-Amz-Date")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Date", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Security-Token")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Security-Token", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Content-Sha256", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Algorithm")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Algorithm", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Signature")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Signature", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-SignedHeaders", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Credential")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Credential", valid_603103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603105: Call_BatchSuspendUser_603092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_603105.validator(path, query, header, formData, body)
  let scheme = call_603105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603105.url(scheme.get, call_603105.host, call_603105.base,
                         call_603105.route, valid.getOrDefault("path"))
  result = hook(call_603105, url, valid)

proc call*(call_603106: Call_BatchSuspendUser_603092; accountId: string;
          body: JsonNode; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603107 = newJObject()
  var query_603108 = newJObject()
  var body_603109 = newJObject()
  add(path_603107, "accountId", newJString(accountId))
  add(query_603108, "operation", newJString(operation))
  if body != nil:
    body_603109 = body
  result = call_603106.call(path_603107, query_603108, nil, nil, body_603109)

var batchSuspendUser* = Call_BatchSuspendUser_603092(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_603093, base: "/",
    url: url_BatchSuspendUser_603094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_603110 = ref object of OpenApiRestCall_602433
proc url_BatchUnsuspendUser_603112(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users#operation=unsuspend")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_BatchUnsuspendUser_603111(path: JsonNode; query: JsonNode;
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
  var valid_603113 = path.getOrDefault("accountId")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = nil)
  if valid_603113 != nil:
    section.add "accountId", valid_603113
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603114 = query.getOrDefault("operation")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_603114 != nil:
    section.add "operation", valid_603114
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
  var valid_603115 = header.getOrDefault("X-Amz-Date")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Date", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Security-Token")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Security-Token", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Content-Sha256", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Algorithm")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Algorithm", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Signature")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Signature", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-SignedHeaders", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Credential")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Credential", valid_603121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603123: Call_BatchUnsuspendUser_603110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_603123.validator(path, query, header, formData, body)
  let scheme = call_603123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603123.url(scheme.get, call_603123.host, call_603123.base,
                         call_603123.route, valid.getOrDefault("path"))
  result = hook(call_603123, url, valid)

proc call*(call_603124: Call_BatchUnsuspendUser_603110; accountId: string;
          body: JsonNode; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603125 = newJObject()
  var query_603126 = newJObject()
  var body_603127 = newJObject()
  add(path_603125, "accountId", newJString(accountId))
  add(query_603126, "operation", newJString(operation))
  if body != nil:
    body_603127 = body
  result = call_603124.call(path_603125, query_603126, nil, nil, body_603127)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_603110(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_603111, base: "/",
    url: url_BatchUnsuspendUser_603112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_603128 = ref object of OpenApiRestCall_602433
proc url_BatchUpdatePhoneNumber_603130(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchUpdatePhoneNumber_603129(path: JsonNode; query: JsonNode;
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
  var valid_603131 = query.getOrDefault("operation")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_603131 != nil:
    section.add "operation", valid_603131
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
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Content-Sha256", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Algorithm")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Algorithm", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Signature")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Signature", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-SignedHeaders", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Credential")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Credential", valid_603138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603140: Call_BatchUpdatePhoneNumber_603128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_603140.validator(path, query, header, formData, body)
  let scheme = call_603140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603140.url(scheme.get, call_603140.host, call_603140.base,
                         call_603140.route, valid.getOrDefault("path"))
  result = hook(call_603140, url, valid)

proc call*(call_603141: Call_BatchUpdatePhoneNumber_603128; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_603142 = newJObject()
  var body_603143 = newJObject()
  add(query_603142, "operation", newJString(operation))
  if body != nil:
    body_603143 = body
  result = call_603141.call(nil, query_603142, nil, nil, body_603143)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_603128(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_603129, base: "/",
    url: url_BatchUpdatePhoneNumber_603130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_603164 = ref object of OpenApiRestCall_602433
proc url_BatchUpdateUser_603166(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_BatchUpdateUser_603165(path: JsonNode; query: JsonNode;
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
  var valid_603167 = path.getOrDefault("accountId")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = nil)
  if valid_603167 != nil:
    section.add "accountId", valid_603167
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
  var valid_603168 = header.getOrDefault("X-Amz-Date")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Date", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Security-Token")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Security-Token", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Content-Sha256", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Algorithm")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Algorithm", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Signature")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Signature", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-SignedHeaders", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Credential")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Credential", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603176: Call_BatchUpdateUser_603164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_603176.validator(path, query, header, formData, body)
  let scheme = call_603176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603176.url(scheme.get, call_603176.host, call_603176.base,
                         call_603176.route, valid.getOrDefault("path"))
  result = hook(call_603176, url, valid)

proc call*(call_603177: Call_BatchUpdateUser_603164; accountId: string;
          body: JsonNode): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603178 = newJObject()
  var body_603179 = newJObject()
  add(path_603178, "accountId", newJString(accountId))
  if body != nil:
    body_603179 = body
  result = call_603177.call(path_603178, nil, nil, nil, body_603179)

var batchUpdateUser* = Call_BatchUpdateUser_603164(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_603165,
    base: "/", url: url_BatchUpdateUser_603166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_603144 = ref object of OpenApiRestCall_602433
proc url_ListUsers_603146(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListUsers_603145(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603147 = path.getOrDefault("accountId")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = nil)
  if valid_603147 != nil:
    section.add "accountId", valid_603147
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
  var valid_603148 = query.getOrDefault("user-email")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "user-email", valid_603148
  var valid_603149 = query.getOrDefault("NextToken")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "NextToken", valid_603149
  var valid_603150 = query.getOrDefault("max-results")
  valid_603150 = validateParameter(valid_603150, JInt, required = false, default = nil)
  if valid_603150 != nil:
    section.add "max-results", valid_603150
  var valid_603151 = query.getOrDefault("next-token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "next-token", valid_603151
  var valid_603152 = query.getOrDefault("MaxResults")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "MaxResults", valid_603152
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
  var valid_603153 = header.getOrDefault("X-Amz-Date")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Date", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Security-Token")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Security-Token", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Content-Sha256", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Algorithm")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Algorithm", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Signature")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Signature", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-SignedHeaders", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Credential")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Credential", valid_603159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_ListUsers_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"))
  result = hook(call_603160, url, valid)

proc call*(call_603161: Call_ListUsers_603144; accountId: string;
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
  var path_603162 = newJObject()
  var query_603163 = newJObject()
  add(path_603162, "accountId", newJString(accountId))
  add(query_603163, "user-email", newJString(userEmail))
  add(query_603163, "NextToken", newJString(NextToken))
  add(query_603163, "max-results", newJInt(maxResults))
  add(query_603163, "next-token", newJString(nextToken))
  add(query_603163, "MaxResults", newJString(MaxResults))
  result = call_603161.call(path_603162, query_603163, nil, nil, nil)

var listUsers* = Call_ListUsers_603144(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_603145,
                                    base: "/", url: url_ListUsers_603146,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_603199 = ref object of OpenApiRestCall_602433
proc url_CreateAccount_603201(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAccount_603200(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603202 = header.getOrDefault("X-Amz-Date")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Date", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Security-Token")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Security-Token", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Content-Sha256", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Algorithm")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Algorithm", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Signature")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Signature", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-SignedHeaders", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Credential")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Credential", valid_603208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603210: Call_CreateAccount_603199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_603210.validator(path, query, header, formData, body)
  let scheme = call_603210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603210.url(scheme.get, call_603210.host, call_603210.base,
                         call_603210.route, valid.getOrDefault("path"))
  result = hook(call_603210, url, valid)

proc call*(call_603211: Call_CreateAccount_603199; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_603212 = newJObject()
  if body != nil:
    body_603212 = body
  result = call_603211.call(nil, nil, nil, nil, body_603212)

var createAccount* = Call_CreateAccount_603199(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_603200, base: "/", url: url_CreateAccount_603201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_603180 = ref object of OpenApiRestCall_602433
proc url_ListAccounts_603182(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAccounts_603181(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603183 = query.getOrDefault("user-email")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "user-email", valid_603183
  var valid_603184 = query.getOrDefault("NextToken")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "NextToken", valid_603184
  var valid_603185 = query.getOrDefault("name")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "name", valid_603185
  var valid_603186 = query.getOrDefault("max-results")
  valid_603186 = validateParameter(valid_603186, JInt, required = false, default = nil)
  if valid_603186 != nil:
    section.add "max-results", valid_603186
  var valid_603187 = query.getOrDefault("next-token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "next-token", valid_603187
  var valid_603188 = query.getOrDefault("MaxResults")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "MaxResults", valid_603188
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
  var valid_603189 = header.getOrDefault("X-Amz-Date")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Date", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Security-Token")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Security-Token", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Content-Sha256", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Algorithm")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Algorithm", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Signature")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Signature", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-SignedHeaders", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Credential")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Credential", valid_603195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_ListAccounts_603180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"))
  result = hook(call_603196, url, valid)

proc call*(call_603197: Call_ListAccounts_603180; userEmail: string = "";
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
  var query_603198 = newJObject()
  add(query_603198, "user-email", newJString(userEmail))
  add(query_603198, "NextToken", newJString(NextToken))
  add(query_603198, "name", newJString(name))
  add(query_603198, "max-results", newJInt(maxResults))
  add(query_603198, "next-token", newJString(nextToken))
  add(query_603198, "MaxResults", newJString(MaxResults))
  result = call_603197.call(nil, query_603198, nil, nil, nil)

var listAccounts* = Call_ListAccounts_603180(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_603181, base: "/", url: url_ListAccounts_603182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_603230 = ref object of OpenApiRestCall_602433
proc url_CreateBot_603232(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateBot_603231(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603233 = path.getOrDefault("accountId")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = nil)
  if valid_603233 != nil:
    section.add "accountId", valid_603233
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
  var valid_603234 = header.getOrDefault("X-Amz-Date")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Date", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Security-Token")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Security-Token", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Content-Sha256", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Algorithm")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Algorithm", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Signature")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Signature", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-SignedHeaders", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Credential")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Credential", valid_603240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603242: Call_CreateBot_603230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_603242.validator(path, query, header, formData, body)
  let scheme = call_603242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603242.url(scheme.get, call_603242.host, call_603242.base,
                         call_603242.route, valid.getOrDefault("path"))
  result = hook(call_603242, url, valid)

proc call*(call_603243: Call_CreateBot_603230; accountId: string; body: JsonNode): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603244 = newJObject()
  var body_603245 = newJObject()
  add(path_603244, "accountId", newJString(accountId))
  if body != nil:
    body_603245 = body
  result = call_603243.call(path_603244, nil, nil, nil, body_603245)

var createBot* = Call_CreateBot_603230(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_603231,
                                    base: "/", url: url_CreateBot_603232,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_603213 = ref object of OpenApiRestCall_602433
proc url_ListBots_603215(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/bots")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListBots_603214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603216 = path.getOrDefault("accountId")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "accountId", valid_603216
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Default is 10.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_603217 = query.getOrDefault("max-results")
  valid_603217 = validateParameter(valid_603217, JInt, required = false, default = nil)
  if valid_603217 != nil:
    section.add "max-results", valid_603217
  var valid_603218 = query.getOrDefault("next-token")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "next-token", valid_603218
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
  var valid_603219 = header.getOrDefault("X-Amz-Date")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Date", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Security-Token")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Security-Token", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Content-Sha256", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Algorithm")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Algorithm", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Signature")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Signature", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-SignedHeaders", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Credential")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Credential", valid_603225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_ListBots_603213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_ListBots_603213; accountId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBots
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Default is 10.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_603228 = newJObject()
  var query_603229 = newJObject()
  add(path_603228, "accountId", newJString(accountId))
  add(query_603229, "max-results", newJInt(maxResults))
  add(query_603229, "next-token", newJString(nextToken))
  result = call_603227.call(path_603228, query_603229, nil, nil, nil)

var listBots* = Call_ListBots_603213(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_603214, base: "/",
                                  url: url_ListBots_603215,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_603263 = ref object of OpenApiRestCall_602433
proc url_CreatePhoneNumberOrder_603265(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePhoneNumberOrder_603264(path: JsonNode; query: JsonNode;
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
  var valid_603266 = header.getOrDefault("X-Amz-Date")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Date", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Security-Token")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Security-Token", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Content-Sha256", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Algorithm")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Algorithm", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Signature")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Signature", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-SignedHeaders", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Credential")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Credential", valid_603272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603274: Call_CreatePhoneNumberOrder_603263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_603274.validator(path, query, header, formData, body)
  let scheme = call_603274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603274.url(scheme.get, call_603274.host, call_603274.base,
                         call_603274.route, valid.getOrDefault("path"))
  result = hook(call_603274, url, valid)

proc call*(call_603275: Call_CreatePhoneNumberOrder_603263; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_603276 = newJObject()
  if body != nil:
    body_603276 = body
  result = call_603275.call(nil, nil, nil, nil, body_603276)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_603263(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_603264, base: "/",
    url: url_CreatePhoneNumberOrder_603265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_603246 = ref object of OpenApiRestCall_602433
proc url_ListPhoneNumberOrders_603248(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPhoneNumberOrders_603247(path: JsonNode; query: JsonNode;
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
  var valid_603249 = query.getOrDefault("NextToken")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "NextToken", valid_603249
  var valid_603250 = query.getOrDefault("max-results")
  valid_603250 = validateParameter(valid_603250, JInt, required = false, default = nil)
  if valid_603250 != nil:
    section.add "max-results", valid_603250
  var valid_603251 = query.getOrDefault("next-token")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "next-token", valid_603251
  var valid_603252 = query.getOrDefault("MaxResults")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "MaxResults", valid_603252
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
  var valid_603253 = header.getOrDefault("X-Amz-Date")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Date", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Security-Token")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Security-Token", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603260: Call_ListPhoneNumberOrders_603246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_603260.validator(path, query, header, formData, body)
  let scheme = call_603260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603260.url(scheme.get, call_603260.host, call_603260.base,
                         call_603260.route, valid.getOrDefault("path"))
  result = hook(call_603260, url, valid)

proc call*(call_603261: Call_ListPhoneNumberOrders_603246; NextToken: string = "";
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
  var query_603262 = newJObject()
  add(query_603262, "NextToken", newJString(NextToken))
  add(query_603262, "max-results", newJInt(maxResults))
  add(query_603262, "next-token", newJString(nextToken))
  add(query_603262, "MaxResults", newJString(MaxResults))
  result = call_603261.call(nil, query_603262, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_603246(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_603247, base: "/",
    url: url_ListPhoneNumberOrders_603248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_603294 = ref object of OpenApiRestCall_602433
proc url_CreateVoiceConnector_603296(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateVoiceConnector_603295(path: JsonNode; query: JsonNode;
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
  var valid_603297 = header.getOrDefault("X-Amz-Date")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Date", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Security-Token")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Security-Token", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Content-Sha256", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Algorithm")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Algorithm", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Signature")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Signature", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-SignedHeaders", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Credential")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Credential", valid_603303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603305: Call_CreateVoiceConnector_603294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ## 
  let valid = call_603305.validator(path, query, header, formData, body)
  let scheme = call_603305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603305.url(scheme.get, call_603305.host, call_603305.base,
                         call_603305.route, valid.getOrDefault("path"))
  result = hook(call_603305, url, valid)

proc call*(call_603306: Call_CreateVoiceConnector_603294; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ##   body: JObject (required)
  var body_603307 = newJObject()
  if body != nil:
    body_603307 = body
  result = call_603306.call(nil, nil, nil, nil, body_603307)

var createVoiceConnector* = Call_CreateVoiceConnector_603294(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_603295, base: "/",
    url: url_CreateVoiceConnector_603296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_603277 = ref object of OpenApiRestCall_602433
proc url_ListVoiceConnectors_603279(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListVoiceConnectors_603278(path: JsonNode; query: JsonNode;
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
  var valid_603280 = query.getOrDefault("NextToken")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "NextToken", valid_603280
  var valid_603281 = query.getOrDefault("max-results")
  valid_603281 = validateParameter(valid_603281, JInt, required = false, default = nil)
  if valid_603281 != nil:
    section.add "max-results", valid_603281
  var valid_603282 = query.getOrDefault("next-token")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "next-token", valid_603282
  var valid_603283 = query.getOrDefault("MaxResults")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "MaxResults", valid_603283
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
  var valid_603284 = header.getOrDefault("X-Amz-Date")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Date", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Security-Token")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Security-Token", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Content-Sha256", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Algorithm")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Algorithm", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Signature")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Signature", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-SignedHeaders", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Credential")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Credential", valid_603290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603291: Call_ListVoiceConnectors_603277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_603291.validator(path, query, header, formData, body)
  let scheme = call_603291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603291.url(scheme.get, call_603291.host, call_603291.base,
                         call_603291.route, valid.getOrDefault("path"))
  result = hook(call_603291, url, valid)

proc call*(call_603292: Call_ListVoiceConnectors_603277; NextToken: string = "";
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
  var query_603293 = newJObject()
  add(query_603293, "NextToken", newJString(NextToken))
  add(query_603293, "max-results", newJInt(maxResults))
  add(query_603293, "next-token", newJString(nextToken))
  add(query_603293, "MaxResults", newJString(MaxResults))
  result = call_603292.call(nil, query_603293, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_603277(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_603278, base: "/",
    url: url_ListVoiceConnectors_603279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_603322 = ref object of OpenApiRestCall_602433
proc url_UpdateAccount_603324(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateAccount_603323(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603325 = path.getOrDefault("accountId")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "accountId", valid_603325
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
  var valid_603326 = header.getOrDefault("X-Amz-Date")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Date", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Security-Token")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Security-Token", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Content-Sha256", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Algorithm")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Algorithm", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Signature")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Signature", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Credential")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Credential", valid_603332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603334: Call_UpdateAccount_603322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_603334.validator(path, query, header, formData, body)
  let scheme = call_603334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603334.url(scheme.get, call_603334.host, call_603334.base,
                         call_603334.route, valid.getOrDefault("path"))
  result = hook(call_603334, url, valid)

proc call*(call_603335: Call_UpdateAccount_603322; accountId: string; body: JsonNode): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603336 = newJObject()
  var body_603337 = newJObject()
  add(path_603336, "accountId", newJString(accountId))
  if body != nil:
    body_603337 = body
  result = call_603335.call(path_603336, nil, nil, nil, body_603337)

var updateAccount* = Call_UpdateAccount_603322(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_603323,
    base: "/", url: url_UpdateAccount_603324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_603308 = ref object of OpenApiRestCall_602433
proc url_GetAccount_603310(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetAccount_603309(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603311 = path.getOrDefault("accountId")
  valid_603311 = validateParameter(valid_603311, JString, required = true,
                                 default = nil)
  if valid_603311 != nil:
    section.add "accountId", valid_603311
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
  var valid_603312 = header.getOrDefault("X-Amz-Date")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Date", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Security-Token")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Security-Token", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Content-Sha256", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Algorithm")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Algorithm", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Signature")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Signature", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-SignedHeaders", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Credential")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Credential", valid_603318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603319: Call_GetAccount_603308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_603319.validator(path, query, header, formData, body)
  let scheme = call_603319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603319.url(scheme.get, call_603319.host, call_603319.base,
                         call_603319.route, valid.getOrDefault("path"))
  result = hook(call_603319, url, valid)

proc call*(call_603320: Call_GetAccount_603308; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_603321 = newJObject()
  add(path_603321, "accountId", newJString(accountId))
  result = call_603320.call(path_603321, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_603308(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_603309,
                                      base: "/", url: url_GetAccount_603310,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_603338 = ref object of OpenApiRestCall_602433
proc url_DeleteAccount_603340(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteAccount_603339(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603341 = path.getOrDefault("accountId")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = nil)
  if valid_603341 != nil:
    section.add "accountId", valid_603341
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
  var valid_603342 = header.getOrDefault("X-Amz-Date")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Date", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Security-Token")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Security-Token", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Content-Sha256", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Algorithm")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Algorithm", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Signature")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Signature", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-SignedHeaders", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Credential")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Credential", valid_603348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603349: Call_DeleteAccount_603338; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_603349.validator(path, query, header, formData, body)
  let scheme = call_603349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603349.url(scheme.get, call_603349.host, call_603349.base,
                         call_603349.route, valid.getOrDefault("path"))
  result = hook(call_603349, url, valid)

proc call*(call_603350: Call_DeleteAccount_603338; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_603351 = newJObject()
  add(path_603351, "accountId", newJString(accountId))
  result = call_603350.call(path_603351, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_603338(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_603339,
    base: "/", url: url_DeleteAccount_603340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_603367 = ref object of OpenApiRestCall_602433
proc url_PutEventsConfiguration_603369(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutEventsConfiguration_603368(path: JsonNode; query: JsonNode;
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
  var valid_603370 = path.getOrDefault("accountId")
  valid_603370 = validateParameter(valid_603370, JString, required = true,
                                 default = nil)
  if valid_603370 != nil:
    section.add "accountId", valid_603370
  var valid_603371 = path.getOrDefault("botId")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "botId", valid_603371
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
  var valid_603372 = header.getOrDefault("X-Amz-Date")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Date", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Security-Token")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Security-Token", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Content-Sha256", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Algorithm")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Algorithm", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Signature")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Signature", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-SignedHeaders", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Credential")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Credential", valid_603378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603380: Call_PutEventsConfiguration_603367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_603380.validator(path, query, header, formData, body)
  let scheme = call_603380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603380.url(scheme.get, call_603380.host, call_603380.base,
                         call_603380.route, valid.getOrDefault("path"))
  result = hook(call_603380, url, valid)

proc call*(call_603381: Call_PutEventsConfiguration_603367; accountId: string;
          botId: string; body: JsonNode): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_603382 = newJObject()
  var body_603383 = newJObject()
  add(path_603382, "accountId", newJString(accountId))
  add(path_603382, "botId", newJString(botId))
  if body != nil:
    body_603383 = body
  result = call_603381.call(path_603382, nil, nil, nil, body_603383)

var putEventsConfiguration* = Call_PutEventsConfiguration_603367(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_603368, base: "/",
    url: url_PutEventsConfiguration_603369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_603352 = ref object of OpenApiRestCall_602433
proc url_GetEventsConfiguration_603354(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetEventsConfiguration_603353(path: JsonNode; query: JsonNode;
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
  var valid_603355 = path.getOrDefault("accountId")
  valid_603355 = validateParameter(valid_603355, JString, required = true,
                                 default = nil)
  if valid_603355 != nil:
    section.add "accountId", valid_603355
  var valid_603356 = path.getOrDefault("botId")
  valid_603356 = validateParameter(valid_603356, JString, required = true,
                                 default = nil)
  if valid_603356 != nil:
    section.add "botId", valid_603356
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
  var valid_603357 = header.getOrDefault("X-Amz-Date")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Date", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Security-Token")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Security-Token", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Content-Sha256", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Algorithm")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Algorithm", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Signature")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Signature", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-SignedHeaders", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Credential")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Credential", valid_603363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603364: Call_GetEventsConfiguration_603352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_603364.validator(path, query, header, formData, body)
  let scheme = call_603364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603364.url(scheme.get, call_603364.host, call_603364.base,
                         call_603364.route, valid.getOrDefault("path"))
  result = hook(call_603364, url, valid)

proc call*(call_603365: Call_GetEventsConfiguration_603352; accountId: string;
          botId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_603366 = newJObject()
  add(path_603366, "accountId", newJString(accountId))
  add(path_603366, "botId", newJString(botId))
  result = call_603365.call(path_603366, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_603352(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_603353, base: "/",
    url: url_GetEventsConfiguration_603354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_603384 = ref object of OpenApiRestCall_602433
proc url_DeleteEventsConfiguration_603386(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteEventsConfiguration_603385(path: JsonNode; query: JsonNode;
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
  var valid_603387 = path.getOrDefault("accountId")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = nil)
  if valid_603387 != nil:
    section.add "accountId", valid_603387
  var valid_603388 = path.getOrDefault("botId")
  valid_603388 = validateParameter(valid_603388, JString, required = true,
                                 default = nil)
  if valid_603388 != nil:
    section.add "botId", valid_603388
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
  var valid_603389 = header.getOrDefault("X-Amz-Date")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Date", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Security-Token")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Security-Token", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Content-Sha256", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Signature")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Signature", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-SignedHeaders", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Credential")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Credential", valid_603395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603396: Call_DeleteEventsConfiguration_603384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_603396.validator(path, query, header, formData, body)
  let scheme = call_603396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603396.url(scheme.get, call_603396.host, call_603396.base,
                         call_603396.route, valid.getOrDefault("path"))
  result = hook(call_603396, url, valid)

proc call*(call_603397: Call_DeleteEventsConfiguration_603384; accountId: string;
          botId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_603398 = newJObject()
  add(path_603398, "accountId", newJString(accountId))
  add(path_603398, "botId", newJString(botId))
  result = call_603397.call(path_603398, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_603384(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_603385, base: "/",
    url: url_DeleteEventsConfiguration_603386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_603413 = ref object of OpenApiRestCall_602433
proc url_UpdatePhoneNumber_603415(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdatePhoneNumber_603414(path: JsonNode; query: JsonNode;
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
  var valid_603416 = path.getOrDefault("phoneNumberId")
  valid_603416 = validateParameter(valid_603416, JString, required = true,
                                 default = nil)
  if valid_603416 != nil:
    section.add "phoneNumberId", valid_603416
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
  var valid_603417 = header.getOrDefault("X-Amz-Date")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Date", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Security-Token")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Security-Token", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Content-Sha256", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Algorithm")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Algorithm", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Signature")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Signature", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-SignedHeaders", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Credential")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Credential", valid_603423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603425: Call_UpdatePhoneNumber_603413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_603425.validator(path, query, header, formData, body)
  let scheme = call_603425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603425.url(scheme.get, call_603425.host, call_603425.base,
                         call_603425.route, valid.getOrDefault("path"))
  result = hook(call_603425, url, valid)

proc call*(call_603426: Call_UpdatePhoneNumber_603413; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_603427 = newJObject()
  var body_603428 = newJObject()
  add(path_603427, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_603428 = body
  result = call_603426.call(path_603427, nil, nil, nil, body_603428)

var updatePhoneNumber* = Call_UpdatePhoneNumber_603413(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_603414, base: "/",
    url: url_UpdatePhoneNumber_603415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_603399 = ref object of OpenApiRestCall_602433
proc url_GetPhoneNumber_603401(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetPhoneNumber_603400(path: JsonNode; query: JsonNode;
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
  var valid_603402 = path.getOrDefault("phoneNumberId")
  valid_603402 = validateParameter(valid_603402, JString, required = true,
                                 default = nil)
  if valid_603402 != nil:
    section.add "phoneNumberId", valid_603402
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
  var valid_603403 = header.getOrDefault("X-Amz-Date")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Date", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Security-Token")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Security-Token", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Content-Sha256", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Algorithm")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Algorithm", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Signature")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Signature", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-SignedHeaders", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Credential")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Credential", valid_603409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603410: Call_GetPhoneNumber_603399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_603410.validator(path, query, header, formData, body)
  let scheme = call_603410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603410.url(scheme.get, call_603410.host, call_603410.base,
                         call_603410.route, valid.getOrDefault("path"))
  result = hook(call_603410, url, valid)

proc call*(call_603411: Call_GetPhoneNumber_603399; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_603412 = newJObject()
  add(path_603412, "phoneNumberId", newJString(phoneNumberId))
  result = call_603411.call(path_603412, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_603399(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_603400,
    base: "/", url: url_GetPhoneNumber_603401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_603429 = ref object of OpenApiRestCall_602433
proc url_DeletePhoneNumber_603431(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeletePhoneNumber_603430(path: JsonNode; query: JsonNode;
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
  var valid_603432 = path.getOrDefault("phoneNumberId")
  valid_603432 = validateParameter(valid_603432, JString, required = true,
                                 default = nil)
  if valid_603432 != nil:
    section.add "phoneNumberId", valid_603432
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
  var valid_603433 = header.getOrDefault("X-Amz-Date")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Date", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Security-Token")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Security-Token", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Content-Sha256", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Algorithm")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Algorithm", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Signature")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Signature", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-SignedHeaders", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Credential")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Credential", valid_603439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603440: Call_DeletePhoneNumber_603429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_603440.validator(path, query, header, formData, body)
  let scheme = call_603440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603440.url(scheme.get, call_603440.host, call_603440.base,
                         call_603440.route, valid.getOrDefault("path"))
  result = hook(call_603440, url, valid)

proc call*(call_603441: Call_DeletePhoneNumber_603429; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_603442 = newJObject()
  add(path_603442, "phoneNumberId", newJString(phoneNumberId))
  result = call_603441.call(path_603442, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_603429(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_603430, base: "/",
    url: url_DeletePhoneNumber_603431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_603457 = ref object of OpenApiRestCall_602433
proc url_UpdateVoiceConnector_603459(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateVoiceConnector_603458(path: JsonNode; query: JsonNode;
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
  var valid_603460 = path.getOrDefault("voiceConnectorId")
  valid_603460 = validateParameter(valid_603460, JString, required = true,
                                 default = nil)
  if valid_603460 != nil:
    section.add "voiceConnectorId", valid_603460
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
  var valid_603461 = header.getOrDefault("X-Amz-Date")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Date", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Security-Token")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Security-Token", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Content-Sha256", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Algorithm")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Algorithm", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Signature")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Signature", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-SignedHeaders", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Credential")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Credential", valid_603467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603469: Call_UpdateVoiceConnector_603457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603469.validator(path, query, header, formData, body)
  let scheme = call_603469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603469.url(scheme.get, call_603469.host, call_603469.base,
                         call_603469.route, valid.getOrDefault("path"))
  result = hook(call_603469, url, valid)

proc call*(call_603470: Call_UpdateVoiceConnector_603457; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_603471 = newJObject()
  var body_603472 = newJObject()
  add(path_603471, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_603472 = body
  result = call_603470.call(path_603471, nil, nil, nil, body_603472)

var updateVoiceConnector* = Call_UpdateVoiceConnector_603457(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_603458, base: "/",
    url: url_UpdateVoiceConnector_603459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_603443 = ref object of OpenApiRestCall_602433
proc url_GetVoiceConnector_603445(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetVoiceConnector_603444(path: JsonNode; query: JsonNode;
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
  var valid_603446 = path.getOrDefault("voiceConnectorId")
  valid_603446 = validateParameter(valid_603446, JString, required = true,
                                 default = nil)
  if valid_603446 != nil:
    section.add "voiceConnectorId", valid_603446
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
  var valid_603447 = header.getOrDefault("X-Amz-Date")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Date", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Security-Token")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Security-Token", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Content-Sha256", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Algorithm")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Algorithm", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Signature")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Signature", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-SignedHeaders", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Credential")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Credential", valid_603453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603454: Call_GetVoiceConnector_603443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_603454.validator(path, query, header, formData, body)
  let scheme = call_603454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603454.url(scheme.get, call_603454.host, call_603454.base,
                         call_603454.route, valid.getOrDefault("path"))
  result = hook(call_603454, url, valid)

proc call*(call_603455: Call_GetVoiceConnector_603443; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603456 = newJObject()
  add(path_603456, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603455.call(path_603456, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_603443(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_603444, base: "/",
    url: url_GetVoiceConnector_603445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_603473 = ref object of OpenApiRestCall_602433
proc url_DeleteVoiceConnector_603475(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "voiceConnectorId" in path,
        "`voiceConnectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/voice-connectors/"),
               (kind: VariableSegment, value: "voiceConnectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVoiceConnector_603474(path: JsonNode; query: JsonNode;
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
  var valid_603476 = path.getOrDefault("voiceConnectorId")
  valid_603476 = validateParameter(valid_603476, JString, required = true,
                                 default = nil)
  if valid_603476 != nil:
    section.add "voiceConnectorId", valid_603476
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
  var valid_603477 = header.getOrDefault("X-Amz-Date")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Date", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Security-Token")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Security-Token", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Content-Sha256", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Algorithm")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Algorithm", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Signature")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Signature", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-SignedHeaders", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Credential")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Credential", valid_603483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603484: Call_DeleteVoiceConnector_603473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ## 
  let valid = call_603484.validator(path, query, header, formData, body)
  let scheme = call_603484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603484.url(scheme.get, call_603484.host, call_603484.base,
                         call_603484.route, valid.getOrDefault("path"))
  result = hook(call_603484, url, valid)

proc call*(call_603485: Call_DeleteVoiceConnector_603473; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603486 = newJObject()
  add(path_603486, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603485.call(path_603486, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_603473(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_603474, base: "/",
    url: url_DeleteVoiceConnector_603475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_603501 = ref object of OpenApiRestCall_602433
proc url_PutVoiceConnectorOrigination_603503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutVoiceConnectorOrigination_603502(path: JsonNode; query: JsonNode;
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
  var valid_603504 = path.getOrDefault("voiceConnectorId")
  valid_603504 = validateParameter(valid_603504, JString, required = true,
                                 default = nil)
  if valid_603504 != nil:
    section.add "voiceConnectorId", valid_603504
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
  var valid_603505 = header.getOrDefault("X-Amz-Date")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Date", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Security-Token")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Security-Token", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Content-Sha256", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Algorithm")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Algorithm", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Signature")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Signature", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-SignedHeaders", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Credential")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Credential", valid_603511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603513: Call_PutVoiceConnectorOrigination_603501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603513.validator(path, query, header, formData, body)
  let scheme = call_603513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603513.url(scheme.get, call_603513.host, call_603513.base,
                         call_603513.route, valid.getOrDefault("path"))
  result = hook(call_603513, url, valid)

proc call*(call_603514: Call_PutVoiceConnectorOrigination_603501;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_603515 = newJObject()
  var body_603516 = newJObject()
  add(path_603515, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_603516 = body
  result = call_603514.call(path_603515, nil, nil, nil, body_603516)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_603501(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_603502, base: "/",
    url: url_PutVoiceConnectorOrigination_603503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_603487 = ref object of OpenApiRestCall_602433
proc url_GetVoiceConnectorOrigination_603489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetVoiceConnectorOrigination_603488(path: JsonNode; query: JsonNode;
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
  var valid_603490 = path.getOrDefault("voiceConnectorId")
  valid_603490 = validateParameter(valid_603490, JString, required = true,
                                 default = nil)
  if valid_603490 != nil:
    section.add "voiceConnectorId", valid_603490
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
  var valid_603491 = header.getOrDefault("X-Amz-Date")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Date", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Security-Token")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Security-Token", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Content-Sha256", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Algorithm")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Algorithm", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Signature")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Signature", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-SignedHeaders", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Credential")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Credential", valid_603497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603498: Call_GetVoiceConnectorOrigination_603487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603498.validator(path, query, header, formData, body)
  let scheme = call_603498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603498.url(scheme.get, call_603498.host, call_603498.base,
                         call_603498.route, valid.getOrDefault("path"))
  result = hook(call_603498, url, valid)

proc call*(call_603499: Call_GetVoiceConnectorOrigination_603487;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603500 = newJObject()
  add(path_603500, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603499.call(path_603500, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_603487(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_603488, base: "/",
    url: url_GetVoiceConnectorOrigination_603489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_603517 = ref object of OpenApiRestCall_602433
proc url_DeleteVoiceConnectorOrigination_603519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVoiceConnectorOrigination_603518(path: JsonNode;
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
  var valid_603520 = path.getOrDefault("voiceConnectorId")
  valid_603520 = validateParameter(valid_603520, JString, required = true,
                                 default = nil)
  if valid_603520 != nil:
    section.add "voiceConnectorId", valid_603520
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
  var valid_603521 = header.getOrDefault("X-Amz-Date")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Date", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Security-Token")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Security-Token", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Content-Sha256", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Algorithm")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Algorithm", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Signature")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Signature", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-SignedHeaders", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Credential")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Credential", valid_603527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603528: Call_DeleteVoiceConnectorOrigination_603517;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603528.validator(path, query, header, formData, body)
  let scheme = call_603528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603528.url(scheme.get, call_603528.host, call_603528.base,
                         call_603528.route, valid.getOrDefault("path"))
  result = hook(call_603528, url, valid)

proc call*(call_603529: Call_DeleteVoiceConnectorOrigination_603517;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603530 = newJObject()
  add(path_603530, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603529.call(path_603530, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_603517(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_603518, base: "/",
    url: url_DeleteVoiceConnectorOrigination_603519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_603545 = ref object of OpenApiRestCall_602433
proc url_PutVoiceConnectorTermination_603547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutVoiceConnectorTermination_603546(path: JsonNode; query: JsonNode;
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
  var valid_603548 = path.getOrDefault("voiceConnectorId")
  valid_603548 = validateParameter(valid_603548, JString, required = true,
                                 default = nil)
  if valid_603548 != nil:
    section.add "voiceConnectorId", valid_603548
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
  var valid_603549 = header.getOrDefault("X-Amz-Date")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Date", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Security-Token")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Security-Token", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Content-Sha256", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Algorithm")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Algorithm", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Signature")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Signature", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-SignedHeaders", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Credential")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Credential", valid_603555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603557: Call_PutVoiceConnectorTermination_603545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603557.validator(path, query, header, formData, body)
  let scheme = call_603557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603557.url(scheme.get, call_603557.host, call_603557.base,
                         call_603557.route, valid.getOrDefault("path"))
  result = hook(call_603557, url, valid)

proc call*(call_603558: Call_PutVoiceConnectorTermination_603545;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_603559 = newJObject()
  var body_603560 = newJObject()
  add(path_603559, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_603560 = body
  result = call_603558.call(path_603559, nil, nil, nil, body_603560)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_603545(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_603546, base: "/",
    url: url_PutVoiceConnectorTermination_603547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_603531 = ref object of OpenApiRestCall_602433
proc url_GetVoiceConnectorTermination_603533(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetVoiceConnectorTermination_603532(path: JsonNode; query: JsonNode;
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
  var valid_603534 = path.getOrDefault("voiceConnectorId")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = nil)
  if valid_603534 != nil:
    section.add "voiceConnectorId", valid_603534
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
  var valid_603535 = header.getOrDefault("X-Amz-Date")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Date", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Security-Token")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Security-Token", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Content-Sha256", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Algorithm")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Algorithm", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Signature")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Signature", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-SignedHeaders", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Credential")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Credential", valid_603541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603542: Call_GetVoiceConnectorTermination_603531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603542.validator(path, query, header, formData, body)
  let scheme = call_603542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603542.url(scheme.get, call_603542.host, call_603542.base,
                         call_603542.route, valid.getOrDefault("path"))
  result = hook(call_603542, url, valid)

proc call*(call_603543: Call_GetVoiceConnectorTermination_603531;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603544 = newJObject()
  add(path_603544, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603543.call(path_603544, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_603531(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_603532, base: "/",
    url: url_GetVoiceConnectorTermination_603533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_603561 = ref object of OpenApiRestCall_602433
proc url_DeleteVoiceConnectorTermination_603563(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVoiceConnectorTermination_603562(path: JsonNode;
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
  var valid_603564 = path.getOrDefault("voiceConnectorId")
  valid_603564 = validateParameter(valid_603564, JString, required = true,
                                 default = nil)
  if valid_603564 != nil:
    section.add "voiceConnectorId", valid_603564
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
  var valid_603565 = header.getOrDefault("X-Amz-Date")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Date", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Security-Token")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Security-Token", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Content-Sha256", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Algorithm")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Algorithm", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Signature")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Signature", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-SignedHeaders", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Credential")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Credential", valid_603571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603572: Call_DeleteVoiceConnectorTermination_603561;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603572.validator(path, query, header, formData, body)
  let scheme = call_603572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603572.url(scheme.get, call_603572.host, call_603572.base,
                         call_603572.route, valid.getOrDefault("path"))
  result = hook(call_603572, url, valid)

proc call*(call_603573: Call_DeleteVoiceConnectorTermination_603561;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603574 = newJObject()
  add(path_603574, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603573.call(path_603574, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_603561(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_603562, base: "/",
    url: url_DeleteVoiceConnectorTermination_603563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_603575 = ref object of OpenApiRestCall_602433
proc url_DeleteVoiceConnectorTerminationCredentials_603577(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVoiceConnectorTerminationCredentials_603576(path: JsonNode;
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
  var valid_603578 = path.getOrDefault("voiceConnectorId")
  valid_603578 = validateParameter(valid_603578, JString, required = true,
                                 default = nil)
  if valid_603578 != nil:
    section.add "voiceConnectorId", valid_603578
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603579 = query.getOrDefault("operation")
  valid_603579 = validateParameter(valid_603579, JString, required = true,
                                 default = newJString("delete"))
  if valid_603579 != nil:
    section.add "operation", valid_603579
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
  var valid_603580 = header.getOrDefault("X-Amz-Date")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Date", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Security-Token")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Security-Token", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Content-Sha256", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Algorithm")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Algorithm", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Signature")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Signature", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-SignedHeaders", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Credential")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Credential", valid_603586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603588: Call_DeleteVoiceConnectorTerminationCredentials_603575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_603588.validator(path, query, header, formData, body)
  let scheme = call_603588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603588.url(scheme.get, call_603588.host, call_603588.base,
                         call_603588.route, valid.getOrDefault("path"))
  result = hook(call_603588, url, valid)

proc call*(call_603589: Call_DeleteVoiceConnectorTerminationCredentials_603575;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603590 = newJObject()
  var query_603591 = newJObject()
  var body_603592 = newJObject()
  add(path_603590, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603591, "operation", newJString(operation))
  if body != nil:
    body_603592 = body
  result = call_603589.call(path_603590, query_603591, nil, nil, body_603592)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_603575(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_603576,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_603577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_603593 = ref object of OpenApiRestCall_602433
proc url_DisassociatePhoneNumberFromUser_603595(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DisassociatePhoneNumberFromUser_603594(path: JsonNode;
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
  var valid_603596 = path.getOrDefault("accountId")
  valid_603596 = validateParameter(valid_603596, JString, required = true,
                                 default = nil)
  if valid_603596 != nil:
    section.add "accountId", valid_603596
  var valid_603597 = path.getOrDefault("userId")
  valid_603597 = validateParameter(valid_603597, JString, required = true,
                                 default = nil)
  if valid_603597 != nil:
    section.add "userId", valid_603597
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603598 = query.getOrDefault("operation")
  valid_603598 = validateParameter(valid_603598, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_603598 != nil:
    section.add "operation", valid_603598
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
  var valid_603599 = header.getOrDefault("X-Amz-Date")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Date", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Security-Token")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Security-Token", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Algorithm")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Algorithm", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Signature")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Signature", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-SignedHeaders", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Credential")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Credential", valid_603605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603606: Call_DisassociatePhoneNumberFromUser_603593;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_603606.validator(path, query, header, formData, body)
  let scheme = call_603606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603606.url(scheme.get, call_603606.host, call_603606.base,
                         call_603606.route, valid.getOrDefault("path"))
  result = hook(call_603606, url, valid)

proc call*(call_603607: Call_DisassociatePhoneNumberFromUser_603593;
          accountId: string; userId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603608 = newJObject()
  var query_603609 = newJObject()
  add(path_603608, "accountId", newJString(accountId))
  add(query_603609, "operation", newJString(operation))
  add(path_603608, "userId", newJString(userId))
  result = call_603607.call(path_603608, query_603609, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_603593(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_603594, base: "/",
    url: url_DisassociatePhoneNumberFromUser_603595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_603610 = ref object of OpenApiRestCall_602433
proc url_DisassociatePhoneNumbersFromVoiceConnector_603612(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DisassociatePhoneNumbersFromVoiceConnector_603611(path: JsonNode;
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
  var valid_603613 = path.getOrDefault("voiceConnectorId")
  valid_603613 = validateParameter(valid_603613, JString, required = true,
                                 default = nil)
  if valid_603613 != nil:
    section.add "voiceConnectorId", valid_603613
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603614 = query.getOrDefault("operation")
  valid_603614 = validateParameter(valid_603614, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_603614 != nil:
    section.add "operation", valid_603614
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
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Content-Sha256", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Algorithm")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Algorithm", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Signature")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Signature", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-SignedHeaders", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Credential")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Credential", valid_603621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603623: Call_DisassociatePhoneNumbersFromVoiceConnector_603610;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603623.validator(path, query, header, formData, body)
  let scheme = call_603623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603623.url(scheme.get, call_603623.host, call_603623.base,
                         call_603623.route, valid.getOrDefault("path"))
  result = hook(call_603623, url, valid)

proc call*(call_603624: Call_DisassociatePhoneNumbersFromVoiceConnector_603610;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603625 = newJObject()
  var query_603626 = newJObject()
  var body_603627 = newJObject()
  add(path_603625, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603626, "operation", newJString(operation))
  if body != nil:
    body_603627 = body
  result = call_603624.call(path_603625, query_603626, nil, nil, body_603627)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_603610(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_603611,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_603612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_603642 = ref object of OpenApiRestCall_602433
proc url_UpdateAccountSettings_603644(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateAccountSettings_603643(path: JsonNode; query: JsonNode;
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
  var valid_603645 = path.getOrDefault("accountId")
  valid_603645 = validateParameter(valid_603645, JString, required = true,
                                 default = nil)
  if valid_603645 != nil:
    section.add "accountId", valid_603645
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
  var valid_603646 = header.getOrDefault("X-Amz-Date")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Date", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Security-Token")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Security-Token", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Content-Sha256", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Algorithm")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Algorithm", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Signature")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Signature", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-SignedHeaders", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Credential")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Credential", valid_603652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603654: Call_UpdateAccountSettings_603642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_603654.validator(path, query, header, formData, body)
  let scheme = call_603654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603654.url(scheme.get, call_603654.host, call_603654.base,
                         call_603654.route, valid.getOrDefault("path"))
  result = hook(call_603654, url, valid)

proc call*(call_603655: Call_UpdateAccountSettings_603642; accountId: string;
          body: JsonNode): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_603656 = newJObject()
  var body_603657 = newJObject()
  add(path_603656, "accountId", newJString(accountId))
  if body != nil:
    body_603657 = body
  result = call_603655.call(path_603656, nil, nil, nil, body_603657)

var updateAccountSettings* = Call_UpdateAccountSettings_603642(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_603643, base: "/",
    url: url_UpdateAccountSettings_603644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_603628 = ref object of OpenApiRestCall_602433
proc url_GetAccountSettings_603630(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/settings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetAccountSettings_603629(path: JsonNode; query: JsonNode;
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
  var valid_603631 = path.getOrDefault("accountId")
  valid_603631 = validateParameter(valid_603631, JString, required = true,
                                 default = nil)
  if valid_603631 != nil:
    section.add "accountId", valid_603631
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

proc call*(call_603639: Call_GetAccountSettings_603628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_GetAccountSettings_603628; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_603641 = newJObject()
  add(path_603641, "accountId", newJString(accountId))
  result = call_603640.call(path_603641, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_603628(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_603629, base: "/",
    url: url_GetAccountSettings_603630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_603673 = ref object of OpenApiRestCall_602433
proc url_UpdateBot_603675(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateBot_603674(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603676 = path.getOrDefault("accountId")
  valid_603676 = validateParameter(valid_603676, JString, required = true,
                                 default = nil)
  if valid_603676 != nil:
    section.add "accountId", valid_603676
  var valid_603677 = path.getOrDefault("botId")
  valid_603677 = validateParameter(valid_603677, JString, required = true,
                                 default = nil)
  if valid_603677 != nil:
    section.add "botId", valid_603677
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
  var valid_603678 = header.getOrDefault("X-Amz-Date")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Date", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Security-Token")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Security-Token", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Content-Sha256", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-Algorithm")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Algorithm", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Signature")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Signature", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-SignedHeaders", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Credential")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Credential", valid_603684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603686: Call_UpdateBot_603673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_603686.validator(path, query, header, formData, body)
  let scheme = call_603686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603686.url(scheme.get, call_603686.host, call_603686.base,
                         call_603686.route, valid.getOrDefault("path"))
  result = hook(call_603686, url, valid)

proc call*(call_603687: Call_UpdateBot_603673; accountId: string; botId: string;
          body: JsonNode): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_603688 = newJObject()
  var body_603689 = newJObject()
  add(path_603688, "accountId", newJString(accountId))
  add(path_603688, "botId", newJString(botId))
  if body != nil:
    body_603689 = body
  result = call_603687.call(path_603688, nil, nil, nil, body_603689)

var updateBot* = Call_UpdateBot_603673(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_603674,
                                    base: "/", url: url_UpdateBot_603675,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_603658 = ref object of OpenApiRestCall_602433
proc url_GetBot_603660(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBot_603659(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603661 = path.getOrDefault("accountId")
  valid_603661 = validateParameter(valid_603661, JString, required = true,
                                 default = nil)
  if valid_603661 != nil:
    section.add "accountId", valid_603661
  var valid_603662 = path.getOrDefault("botId")
  valid_603662 = validateParameter(valid_603662, JString, required = true,
                                 default = nil)
  if valid_603662 != nil:
    section.add "botId", valid_603662
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
  var valid_603663 = header.getOrDefault("X-Amz-Date")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Date", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Security-Token")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Security-Token", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Content-Sha256", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Algorithm")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Algorithm", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Signature")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Signature", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-SignedHeaders", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Credential")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Credential", valid_603669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603670: Call_GetBot_603658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_603670.validator(path, query, header, formData, body)
  let scheme = call_603670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603670.url(scheme.get, call_603670.host, call_603670.base,
                         call_603670.route, valid.getOrDefault("path"))
  result = hook(call_603670, url, valid)

proc call*(call_603671: Call_GetBot_603658; accountId: string; botId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_603672 = newJObject()
  add(path_603672, "accountId", newJString(accountId))
  add(path_603672, "botId", newJString(botId))
  result = call_603671.call(path_603672, nil, nil, nil, nil)

var getBot* = Call_GetBot_603658(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_603659, base: "/",
                              url: url_GetBot_603660,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_603702 = ref object of OpenApiRestCall_602433
proc url_UpdateGlobalSettings_603704(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGlobalSettings_603703(path: JsonNode; query: JsonNode;
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
  var valid_603705 = header.getOrDefault("X-Amz-Date")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Date", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Security-Token")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Security-Token", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Content-Sha256", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Algorithm")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Algorithm", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Signature")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Signature", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-SignedHeaders", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Credential")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Credential", valid_603711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603713: Call_UpdateGlobalSettings_603702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_603713.validator(path, query, header, formData, body)
  let scheme = call_603713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603713.url(scheme.get, call_603713.host, call_603713.base,
                         call_603713.route, valid.getOrDefault("path"))
  result = hook(call_603713, url, valid)

proc call*(call_603714: Call_UpdateGlobalSettings_603702; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_603715 = newJObject()
  if body != nil:
    body_603715 = body
  result = call_603714.call(nil, nil, nil, nil, body_603715)

var updateGlobalSettings* = Call_UpdateGlobalSettings_603702(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_603703, base: "/",
    url: url_UpdateGlobalSettings_603704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_603690 = ref object of OpenApiRestCall_602433
proc url_GetGlobalSettings_603692(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGlobalSettings_603691(path: JsonNode; query: JsonNode;
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
  var valid_603693 = header.getOrDefault("X-Amz-Date")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Date", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Security-Token")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Security-Token", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Content-Sha256", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Algorithm")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Algorithm", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Signature")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Signature", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-SignedHeaders", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Credential")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Credential", valid_603699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603700: Call_GetGlobalSettings_603690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_603700.validator(path, query, header, formData, body)
  let scheme = call_603700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603700.url(scheme.get, call_603700.host, call_603700.base,
                         call_603700.route, valid.getOrDefault("path"))
  result = hook(call_603700, url, valid)

proc call*(call_603701: Call_GetGlobalSettings_603690): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_603701.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_603690(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_603691, base: "/",
    url: url_GetGlobalSettings_603692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_603716 = ref object of OpenApiRestCall_602433
proc url_GetPhoneNumberOrder_603718(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberOrderId" in path,
        "`phoneNumberOrderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-number-orders/"),
               (kind: VariableSegment, value: "phoneNumberOrderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetPhoneNumberOrder_603717(path: JsonNode; query: JsonNode;
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
  var valid_603719 = path.getOrDefault("phoneNumberOrderId")
  valid_603719 = validateParameter(valid_603719, JString, required = true,
                                 default = nil)
  if valid_603719 != nil:
    section.add "phoneNumberOrderId", valid_603719
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
  var valid_603720 = header.getOrDefault("X-Amz-Date")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Date", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Security-Token")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Security-Token", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Content-Sha256", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Algorithm")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Algorithm", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Signature")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Signature", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-SignedHeaders", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Credential")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Credential", valid_603726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603727: Call_GetPhoneNumberOrder_603716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_603727.validator(path, query, header, formData, body)
  let scheme = call_603727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603727.url(scheme.get, call_603727.host, call_603727.base,
                         call_603727.route, valid.getOrDefault("path"))
  result = hook(call_603727, url, valid)

proc call*(call_603728: Call_GetPhoneNumberOrder_603716; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_603729 = newJObject()
  add(path_603729, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_603728.call(path_603729, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_603716(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_603717, base: "/",
    url: url_GetPhoneNumberOrder_603718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_603745 = ref object of OpenApiRestCall_602433
proc url_UpdateUser_603747(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateUser_603746(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603748 = path.getOrDefault("accountId")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = nil)
  if valid_603748 != nil:
    section.add "accountId", valid_603748
  var valid_603749 = path.getOrDefault("userId")
  valid_603749 = validateParameter(valid_603749, JString, required = true,
                                 default = nil)
  if valid_603749 != nil:
    section.add "userId", valid_603749
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
  var valid_603750 = header.getOrDefault("X-Amz-Date")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Date", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Security-Token")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Security-Token", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Content-Sha256", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Algorithm")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Algorithm", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Signature")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Signature", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-SignedHeaders", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-Credential")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Credential", valid_603756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603758: Call_UpdateUser_603745; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_603758.validator(path, query, header, formData, body)
  let scheme = call_603758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603758.url(scheme.get, call_603758.host, call_603758.base,
                         call_603758.route, valid.getOrDefault("path"))
  result = hook(call_603758, url, valid)

proc call*(call_603759: Call_UpdateUser_603745; accountId: string; body: JsonNode;
          userId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603760 = newJObject()
  var body_603761 = newJObject()
  add(path_603760, "accountId", newJString(accountId))
  if body != nil:
    body_603761 = body
  add(path_603760, "userId", newJString(userId))
  result = call_603759.call(path_603760, nil, nil, nil, body_603761)

var updateUser* = Call_UpdateUser_603745(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_603746,
                                      base: "/", url: url_UpdateUser_603747,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_603730 = ref object of OpenApiRestCall_602433
proc url_GetUser_603732(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUser_603731(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603733 = path.getOrDefault("accountId")
  valid_603733 = validateParameter(valid_603733, JString, required = true,
                                 default = nil)
  if valid_603733 != nil:
    section.add "accountId", valid_603733
  var valid_603734 = path.getOrDefault("userId")
  valid_603734 = validateParameter(valid_603734, JString, required = true,
                                 default = nil)
  if valid_603734 != nil:
    section.add "userId", valid_603734
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
  var valid_603735 = header.getOrDefault("X-Amz-Date")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Date", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Security-Token")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Security-Token", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Content-Sha256", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Algorithm")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Algorithm", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Signature")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Signature", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-SignedHeaders", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Credential")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Credential", valid_603741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603742: Call_GetUser_603730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_603742.validator(path, query, header, formData, body)
  let scheme = call_603742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603742.url(scheme.get, call_603742.host, call_603742.base,
                         call_603742.route, valid.getOrDefault("path"))
  result = hook(call_603742, url, valid)

proc call*(call_603743: Call_GetUser_603730; accountId: string; userId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_603744 = newJObject()
  add(path_603744, "accountId", newJString(accountId))
  add(path_603744, "userId", newJString(userId))
  result = call_603743.call(path_603744, nil, nil, nil, nil)

var getUser* = Call_GetUser_603730(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_603731, base: "/",
                                url: url_GetUser_603732,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_603777 = ref object of OpenApiRestCall_602433
proc url_UpdateUserSettings_603779(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateUserSettings_603778(path: JsonNode; query: JsonNode;
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
  var valid_603780 = path.getOrDefault("accountId")
  valid_603780 = validateParameter(valid_603780, JString, required = true,
                                 default = nil)
  if valid_603780 != nil:
    section.add "accountId", valid_603780
  var valid_603781 = path.getOrDefault("userId")
  valid_603781 = validateParameter(valid_603781, JString, required = true,
                                 default = nil)
  if valid_603781 != nil:
    section.add "userId", valid_603781
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
  var valid_603782 = header.getOrDefault("X-Amz-Date")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Date", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Security-Token")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Security-Token", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Content-Sha256", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Algorithm")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Algorithm", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Signature")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Signature", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-SignedHeaders", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Credential")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Credential", valid_603788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603790: Call_UpdateUserSettings_603777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_603790.validator(path, query, header, formData, body)
  let scheme = call_603790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603790.url(scheme.get, call_603790.host, call_603790.base,
                         call_603790.route, valid.getOrDefault("path"))
  result = hook(call_603790, url, valid)

proc call*(call_603791: Call_UpdateUserSettings_603777; accountId: string;
          body: JsonNode; userId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603792 = newJObject()
  var body_603793 = newJObject()
  add(path_603792, "accountId", newJString(accountId))
  if body != nil:
    body_603793 = body
  add(path_603792, "userId", newJString(userId))
  result = call_603791.call(path_603792, nil, nil, nil, body_603793)

var updateUserSettings* = Call_UpdateUserSettings_603777(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_603778, base: "/",
    url: url_UpdateUserSettings_603779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_603762 = ref object of OpenApiRestCall_602433
proc url_GetUserSettings_603764(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetUserSettings_603763(path: JsonNode; query: JsonNode;
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
  var valid_603765 = path.getOrDefault("accountId")
  valid_603765 = validateParameter(valid_603765, JString, required = true,
                                 default = nil)
  if valid_603765 != nil:
    section.add "accountId", valid_603765
  var valid_603766 = path.getOrDefault("userId")
  valid_603766 = validateParameter(valid_603766, JString, required = true,
                                 default = nil)
  if valid_603766 != nil:
    section.add "userId", valid_603766
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
  var valid_603767 = header.getOrDefault("X-Amz-Date")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Date", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Security-Token")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Security-Token", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Content-Sha256", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Algorithm")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Algorithm", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-Signature")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Signature", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-SignedHeaders", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Credential")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Credential", valid_603773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603774: Call_GetUserSettings_603762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_603774.validator(path, query, header, formData, body)
  let scheme = call_603774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603774.url(scheme.get, call_603774.host, call_603774.base,
                         call_603774.route, valid.getOrDefault("path"))
  result = hook(call_603774, url, valid)

proc call*(call_603775: Call_GetUserSettings_603762; accountId: string;
          userId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_603776 = newJObject()
  add(path_603776, "accountId", newJString(accountId))
  add(path_603776, "userId", newJString(userId))
  result = call_603775.call(path_603776, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_603762(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_603763, base: "/", url: url_GetUserSettings_603764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_603794 = ref object of OpenApiRestCall_602433
proc url_GetVoiceConnectorTerminationHealth_603796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetVoiceConnectorTerminationHealth_603795(path: JsonNode;
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
  var valid_603797 = path.getOrDefault("voiceConnectorId")
  valid_603797 = validateParameter(valid_603797, JString, required = true,
                                 default = nil)
  if valid_603797 != nil:
    section.add "voiceConnectorId", valid_603797
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
  var valid_603798 = header.getOrDefault("X-Amz-Date")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Date", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Security-Token")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Security-Token", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Content-Sha256", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Algorithm")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Algorithm", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Signature")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Signature", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-SignedHeaders", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Credential")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Credential", valid_603804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603805: Call_GetVoiceConnectorTerminationHealth_603794;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603805.validator(path, query, header, formData, body)
  let scheme = call_603805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603805.url(scheme.get, call_603805.host, call_603805.base,
                         call_603805.route, valid.getOrDefault("path"))
  result = hook(call_603805, url, valid)

proc call*(call_603806: Call_GetVoiceConnectorTerminationHealth_603794;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603807 = newJObject()
  add(path_603807, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603806.call(path_603807, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_603794(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_603795, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_603796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_603808 = ref object of OpenApiRestCall_602433
proc url_InviteUsers_603810(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/users#operation=add")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_InviteUsers_603809(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603811 = path.getOrDefault("accountId")
  valid_603811 = validateParameter(valid_603811, JString, required = true,
                                 default = nil)
  if valid_603811 != nil:
    section.add "accountId", valid_603811
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603812 = query.getOrDefault("operation")
  valid_603812 = validateParameter(valid_603812, JString, required = true,
                                 default = newJString("add"))
  if valid_603812 != nil:
    section.add "operation", valid_603812
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
  var valid_603813 = header.getOrDefault("X-Amz-Date")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Date", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Security-Token")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Security-Token", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Content-Sha256", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Algorithm")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Algorithm", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Signature")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Signature", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-SignedHeaders", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Credential")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Credential", valid_603819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603821: Call_InviteUsers_603808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_603821.validator(path, query, header, formData, body)
  let scheme = call_603821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603821.url(scheme.get, call_603821.host, call_603821.base,
                         call_603821.route, valid.getOrDefault("path"))
  result = hook(call_603821, url, valid)

proc call*(call_603822: Call_InviteUsers_603808; accountId: string; body: JsonNode;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603823 = newJObject()
  var query_603824 = newJObject()
  var body_603825 = newJObject()
  add(path_603823, "accountId", newJString(accountId))
  add(query_603824, "operation", newJString(operation))
  if body != nil:
    body_603825 = body
  result = call_603822.call(path_603823, query_603824, nil, nil, body_603825)

var inviteUsers* = Call_InviteUsers_603808(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_603809,
                                        base: "/", url: url_InviteUsers_603810,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_603826 = ref object of OpenApiRestCall_602433
proc url_ListPhoneNumbers_603828(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPhoneNumbers_603827(path: JsonNode; query: JsonNode;
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
  var valid_603829 = query.getOrDefault("filter-name")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_603829 != nil:
    section.add "filter-name", valid_603829
  var valid_603830 = query.getOrDefault("NextToken")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "NextToken", valid_603830
  var valid_603831 = query.getOrDefault("max-results")
  valid_603831 = validateParameter(valid_603831, JInt, required = false, default = nil)
  if valid_603831 != nil:
    section.add "max-results", valid_603831
  var valid_603832 = query.getOrDefault("filter-value")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "filter-value", valid_603832
  var valid_603833 = query.getOrDefault("status")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_603833 != nil:
    section.add "status", valid_603833
  var valid_603834 = query.getOrDefault("product-type")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_603834 != nil:
    section.add "product-type", valid_603834
  var valid_603835 = query.getOrDefault("next-token")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "next-token", valid_603835
  var valid_603836 = query.getOrDefault("MaxResults")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "MaxResults", valid_603836
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
  var valid_603837 = header.getOrDefault("X-Amz-Date")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Date", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Security-Token")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Security-Token", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Content-Sha256", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Algorithm")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Algorithm", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Signature")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Signature", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-SignedHeaders", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Credential")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Credential", valid_603843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603844: Call_ListPhoneNumbers_603826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
  ## 
  let valid = call_603844.validator(path, query, header, formData, body)
  let scheme = call_603844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603844.url(scheme.get, call_603844.host, call_603844.base,
                         call_603844.route, valid.getOrDefault("path"))
  result = hook(call_603844, url, valid)

proc call*(call_603845: Call_ListPhoneNumbers_603826;
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
  var query_603846 = newJObject()
  add(query_603846, "filter-name", newJString(filterName))
  add(query_603846, "NextToken", newJString(NextToken))
  add(query_603846, "max-results", newJInt(maxResults))
  add(query_603846, "filter-value", newJString(filterValue))
  add(query_603846, "status", newJString(status))
  add(query_603846, "product-type", newJString(productType))
  add(query_603846, "next-token", newJString(nextToken))
  add(query_603846, "MaxResults", newJString(MaxResults))
  result = call_603845.call(nil, query_603846, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_603826(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_603827, base: "/",
    url: url_ListPhoneNumbers_603828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_603847 = ref object of OpenApiRestCall_602433
proc url_ListVoiceConnectorTerminationCredentials_603849(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListVoiceConnectorTerminationCredentials_603848(path: JsonNode;
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
  var valid_603850 = path.getOrDefault("voiceConnectorId")
  valid_603850 = validateParameter(valid_603850, JString, required = true,
                                 default = nil)
  if valid_603850 != nil:
    section.add "voiceConnectorId", valid_603850
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
  var valid_603851 = header.getOrDefault("X-Amz-Date")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Date", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Security-Token")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Security-Token", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Content-Sha256", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Algorithm")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Algorithm", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Signature")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Signature", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-SignedHeaders", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Credential")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Credential", valid_603857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603858: Call_ListVoiceConnectorTerminationCredentials_603847;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603858.validator(path, query, header, formData, body)
  let scheme = call_603858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603858.url(scheme.get, call_603858.host, call_603858.base,
                         call_603858.route, valid.getOrDefault("path"))
  result = hook(call_603858, url, valid)

proc call*(call_603859: Call_ListVoiceConnectorTerminationCredentials_603847;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_603860 = newJObject()
  add(path_603860, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_603859.call(path_603860, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_603847(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_603848,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_603849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_603861 = ref object of OpenApiRestCall_602433
proc url_LogoutUser_603863(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_LogoutUser_603862(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603864 = path.getOrDefault("accountId")
  valid_603864 = validateParameter(valid_603864, JString, required = true,
                                 default = nil)
  if valid_603864 != nil:
    section.add "accountId", valid_603864
  var valid_603865 = path.getOrDefault("userId")
  valid_603865 = validateParameter(valid_603865, JString, required = true,
                                 default = nil)
  if valid_603865 != nil:
    section.add "userId", valid_603865
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603866 = query.getOrDefault("operation")
  valid_603866 = validateParameter(valid_603866, JString, required = true,
                                 default = newJString("logout"))
  if valid_603866 != nil:
    section.add "operation", valid_603866
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
  var valid_603867 = header.getOrDefault("X-Amz-Date")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Date", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Security-Token")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Security-Token", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Content-Sha256", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Algorithm")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Algorithm", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Signature")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Signature", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-SignedHeaders", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Credential")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Credential", valid_603873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603874: Call_LogoutUser_603861; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_603874.validator(path, query, header, formData, body)
  let scheme = call_603874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603874.url(scheme.get, call_603874.host, call_603874.base,
                         call_603874.route, valid.getOrDefault("path"))
  result = hook(call_603874, url, valid)

proc call*(call_603875: Call_LogoutUser_603861; accountId: string; userId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603876 = newJObject()
  var query_603877 = newJObject()
  add(path_603876, "accountId", newJString(accountId))
  add(query_603877, "operation", newJString(operation))
  add(path_603876, "userId", newJString(userId))
  result = call_603875.call(path_603876, query_603877, nil, nil, nil)

var logoutUser* = Call_LogoutUser_603861(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_603862,
                                      base: "/", url: url_LogoutUser_603863,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_603878 = ref object of OpenApiRestCall_602433
proc url_PutVoiceConnectorTerminationCredentials_603880(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutVoiceConnectorTerminationCredentials_603879(path: JsonNode;
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
  var valid_603881 = path.getOrDefault("voiceConnectorId")
  valid_603881 = validateParameter(valid_603881, JString, required = true,
                                 default = nil)
  if valid_603881 != nil:
    section.add "voiceConnectorId", valid_603881
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603882 = query.getOrDefault("operation")
  valid_603882 = validateParameter(valid_603882, JString, required = true,
                                 default = newJString("put"))
  if valid_603882 != nil:
    section.add "operation", valid_603882
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
  var valid_603883 = header.getOrDefault("X-Amz-Date")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Date", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Security-Token")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Security-Token", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Content-Sha256", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Algorithm")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Algorithm", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Signature")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Signature", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-SignedHeaders", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Credential")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Credential", valid_603889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603891: Call_PutVoiceConnectorTerminationCredentials_603878;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_603891.validator(path, query, header, formData, body)
  let scheme = call_603891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603891.url(scheme.get, call_603891.host, call_603891.base,
                         call_603891.route, valid.getOrDefault("path"))
  result = hook(call_603891, url, valid)

proc call*(call_603892: Call_PutVoiceConnectorTerminationCredentials_603878;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603893 = newJObject()
  var query_603894 = newJObject()
  var body_603895 = newJObject()
  add(path_603893, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_603894, "operation", newJString(operation))
  if body != nil:
    body_603895 = body
  result = call_603892.call(path_603893, query_603894, nil, nil, body_603895)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_603878(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_603879, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_603880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_603896 = ref object of OpenApiRestCall_602433
proc url_RegenerateSecurityToken_603898(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_RegenerateSecurityToken_603897(path: JsonNode; query: JsonNode;
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
  var valid_603899 = path.getOrDefault("accountId")
  valid_603899 = validateParameter(valid_603899, JString, required = true,
                                 default = nil)
  if valid_603899 != nil:
    section.add "accountId", valid_603899
  var valid_603900 = path.getOrDefault("botId")
  valid_603900 = validateParameter(valid_603900, JString, required = true,
                                 default = nil)
  if valid_603900 != nil:
    section.add "botId", valid_603900
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603901 = query.getOrDefault("operation")
  valid_603901 = validateParameter(valid_603901, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_603901 != nil:
    section.add "operation", valid_603901
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
  var valid_603902 = header.getOrDefault("X-Amz-Date")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Date", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Security-Token")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Security-Token", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Content-Sha256", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Algorithm")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Algorithm", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Signature")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Signature", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-SignedHeaders", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Credential")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Credential", valid_603908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603909: Call_RegenerateSecurityToken_603896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_603909.validator(path, query, header, formData, body)
  let scheme = call_603909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603909.url(scheme.get, call_603909.host, call_603909.base,
                         call_603909.route, valid.getOrDefault("path"))
  result = hook(call_603909, url, valid)

proc call*(call_603910: Call_RegenerateSecurityToken_603896; accountId: string;
          botId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  var path_603911 = newJObject()
  var query_603912 = newJObject()
  add(path_603911, "accountId", newJString(accountId))
  add(path_603911, "botId", newJString(botId))
  add(query_603912, "operation", newJString(operation))
  result = call_603910.call(path_603911, query_603912, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_603896(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_603897, base: "/",
    url: url_RegenerateSecurityToken_603898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_603913 = ref object of OpenApiRestCall_602433
proc url_ResetPersonalPIN_603915(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ResetPersonalPIN_603914(path: JsonNode; query: JsonNode;
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
  var valid_603916 = path.getOrDefault("accountId")
  valid_603916 = validateParameter(valid_603916, JString, required = true,
                                 default = nil)
  if valid_603916 != nil:
    section.add "accountId", valid_603916
  var valid_603917 = path.getOrDefault("userId")
  valid_603917 = validateParameter(valid_603917, JString, required = true,
                                 default = nil)
  if valid_603917 != nil:
    section.add "userId", valid_603917
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603918 = query.getOrDefault("operation")
  valid_603918 = validateParameter(valid_603918, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_603918 != nil:
    section.add "operation", valid_603918
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
  var valid_603919 = header.getOrDefault("X-Amz-Date")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Date", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Security-Token")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Security-Token", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Content-Sha256", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Algorithm")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Algorithm", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Signature")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Signature", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-SignedHeaders", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Credential")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Credential", valid_603925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603926: Call_ResetPersonalPIN_603913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_603926.validator(path, query, header, formData, body)
  let scheme = call_603926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603926.url(scheme.get, call_603926.host, call_603926.base,
                         call_603926.route, valid.getOrDefault("path"))
  result = hook(call_603926, url, valid)

proc call*(call_603927: Call_ResetPersonalPIN_603913; accountId: string;
          userId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_603928 = newJObject()
  var query_603929 = newJObject()
  add(path_603928, "accountId", newJString(accountId))
  add(query_603929, "operation", newJString(operation))
  add(path_603928, "userId", newJString(userId))
  result = call_603927.call(path_603928, query_603929, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_603913(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_603914, base: "/",
    url: url_ResetPersonalPIN_603915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_603930 = ref object of OpenApiRestCall_602433
proc url_RestorePhoneNumber_603932(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId"),
               (kind: ConstantSegment, value: "#operation=restore")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_RestorePhoneNumber_603931(path: JsonNode; query: JsonNode;
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
  var valid_603933 = path.getOrDefault("phoneNumberId")
  valid_603933 = validateParameter(valid_603933, JString, required = true,
                                 default = nil)
  if valid_603933 != nil:
    section.add "phoneNumberId", valid_603933
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603934 = query.getOrDefault("operation")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = newJString("restore"))
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

proc call*(call_603942: Call_RestorePhoneNumber_603930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_603942.validator(path, query, header, formData, body)
  let scheme = call_603942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603942.url(scheme.get, call_603942.host, call_603942.base,
                         call_603942.route, valid.getOrDefault("path"))
  result = hook(call_603942, url, valid)

proc call*(call_603943: Call_RestorePhoneNumber_603930; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_603944 = newJObject()
  var query_603945 = newJObject()
  add(path_603944, "phoneNumberId", newJString(phoneNumberId))
  add(query_603945, "operation", newJString(operation))
  result = call_603943.call(path_603944, query_603945, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_603930(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_603931, base: "/",
    url: url_RestorePhoneNumber_603932, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_603946 = ref object of OpenApiRestCall_602433
proc url_SearchAvailablePhoneNumbers_603948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchAvailablePhoneNumbers_603947(path: JsonNode; query: JsonNode;
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
  var valid_603949 = query.getOrDefault("city")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "city", valid_603949
  var valid_603950 = query.getOrDefault("toll-free-prefix")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "toll-free-prefix", valid_603950
  var valid_603951 = query.getOrDefault("country")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "country", valid_603951
  var valid_603952 = query.getOrDefault("area-code")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "area-code", valid_603952
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_603953 = query.getOrDefault("type")
  valid_603953 = validateParameter(valid_603953, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_603953 != nil:
    section.add "type", valid_603953
  var valid_603954 = query.getOrDefault("max-results")
  valid_603954 = validateParameter(valid_603954, JInt, required = false, default = nil)
  if valid_603954 != nil:
    section.add "max-results", valid_603954
  var valid_603955 = query.getOrDefault("next-token")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "next-token", valid_603955
  var valid_603956 = query.getOrDefault("state")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "state", valid_603956
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
  var valid_603957 = header.getOrDefault("X-Amz-Date")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Date", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Security-Token")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Security-Token", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Content-Sha256", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Algorithm")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Algorithm", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Signature")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Signature", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-SignedHeaders", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-Credential")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-Credential", valid_603963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603964: Call_SearchAvailablePhoneNumbers_603946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_603964.validator(path, query, header, formData, body)
  let scheme = call_603964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603964.url(scheme.get, call_603964.host, call_603964.base,
                         call_603964.route, valid.getOrDefault("path"))
  result = hook(call_603964, url, valid)

proc call*(call_603965: Call_SearchAvailablePhoneNumbers_603946; city: string = "";
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
  var query_603966 = newJObject()
  add(query_603966, "city", newJString(city))
  add(query_603966, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_603966, "country", newJString(country))
  add(query_603966, "area-code", newJString(areaCode))
  add(query_603966, "type", newJString(`type`))
  add(query_603966, "max-results", newJInt(maxResults))
  add(query_603966, "next-token", newJString(nextToken))
  add(query_603966, "state", newJString(state))
  result = call_603965.call(nil, query_603966, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_603946(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_603947, base: "/",
    url: url_SearchAvailablePhoneNumbers_603948,
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
