
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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"cn-northwest-1": "chime.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "chime.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "chime.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "chime.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "chime"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociatePhoneNumberWithUser_600768 = ref object of OpenApiRestCall_600426
proc url_AssociatePhoneNumberWithUser_600770(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AssociatePhoneNumberWithUser_600769(path: JsonNode; query: JsonNode;
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
  var valid_600896 = path.getOrDefault("accountId")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "accountId", valid_600896
  var valid_600897 = path.getOrDefault("userId")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = nil)
  if valid_600897 != nil:
    section.add "userId", valid_600897
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_600911 = query.getOrDefault("operation")
  valid_600911 = validateParameter(valid_600911, JString, required = true,
                                 default = newJString("associate-phone-number"))
  if valid_600911 != nil:
    section.add "operation", valid_600911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600912 = header.getOrDefault("X-Amz-Date")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Date", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-Security-Token")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-Security-Token", valid_600913
  var valid_600914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Content-Sha256", valid_600914
  var valid_600915 = header.getOrDefault("X-Amz-Algorithm")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-Algorithm", valid_600915
  var valid_600916 = header.getOrDefault("X-Amz-Signature")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "X-Amz-Signature", valid_600916
  var valid_600917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-SignedHeaders", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Credential")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Credential", valid_600918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600942: Call_AssociatePhoneNumberWithUser_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime user.
  ## 
  let valid = call_600942.validator(path, query, header, formData, body)
  let scheme = call_600942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600942.url(scheme.get, call_600942.host, call_600942.base,
                         call_600942.route, valid.getOrDefault("path"))
  result = hook(call_600942, url, valid)

proc call*(call_601013: Call_AssociatePhoneNumberWithUser_600768;
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
  var path_601014 = newJObject()
  var query_601016 = newJObject()
  var body_601017 = newJObject()
  add(path_601014, "accountId", newJString(accountId))
  add(query_601016, "operation", newJString(operation))
  if body != nil:
    body_601017 = body
  add(path_601014, "userId", newJString(userId))
  result = call_601013.call(path_601014, query_601016, nil, nil, body_601017)

var associatePhoneNumberWithUser* = Call_AssociatePhoneNumberWithUser_600768(
    name: "associatePhoneNumberWithUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=associate-phone-number",
    validator: validate_AssociatePhoneNumberWithUser_600769, base: "/",
    url: url_AssociatePhoneNumberWithUser_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePhoneNumbersWithVoiceConnector_601056 = ref object of OpenApiRestCall_600426
proc url_AssociatePhoneNumbersWithVoiceConnector_601058(protocol: Scheme;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AssociatePhoneNumbersWithVoiceConnector_601057(path: JsonNode;
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
  var valid_601059 = path.getOrDefault("voiceConnectorId")
  valid_601059 = validateParameter(valid_601059, JString, required = true,
                                 default = nil)
  if valid_601059 != nil:
    section.add "voiceConnectorId", valid_601059
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601060 = query.getOrDefault("operation")
  valid_601060 = validateParameter(valid_601060, JString, required = true, default = newJString(
      "associate-phone-numbers"))
  if valid_601060 != nil:
    section.add "operation", valid_601060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Content-Sha256", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Algorithm")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Algorithm", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Signature")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Signature", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-SignedHeaders", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Credential")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Credential", valid_601067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601069: Call_AssociatePhoneNumbersWithVoiceConnector_601056;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601069.validator(path, query, header, formData, body)
  let scheme = call_601069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601069.url(scheme.get, call_601069.host, call_601069.base,
                         call_601069.route, valid.getOrDefault("path"))
  result = hook(call_601069, url, valid)

proc call*(call_601070: Call_AssociatePhoneNumbersWithVoiceConnector_601056;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "associate-phone-numbers"): Recallable =
  ## associatePhoneNumbersWithVoiceConnector
  ## Associates a phone number with the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601071 = newJObject()
  var query_601072 = newJObject()
  var body_601073 = newJObject()
  add(path_601071, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_601072, "operation", newJString(operation))
  if body != nil:
    body_601073 = body
  result = call_601070.call(path_601071, query_601072, nil, nil, body_601073)

var associatePhoneNumbersWithVoiceConnector* = Call_AssociatePhoneNumbersWithVoiceConnector_601056(
    name: "associatePhoneNumbersWithVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=associate-phone-numbers",
    validator: validate_AssociatePhoneNumbersWithVoiceConnector_601057, base: "/",
    url: url_AssociatePhoneNumbersWithVoiceConnector_601058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePhoneNumber_601074 = ref object of OpenApiRestCall_600426
proc url_BatchDeletePhoneNumber_601076(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeletePhoneNumber_601075(path: JsonNode; query: JsonNode;
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
  var valid_601077 = query.getOrDefault("operation")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = newJString("batch-delete"))
  if valid_601077 != nil:
    section.add "operation", valid_601077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601078 = header.getOrDefault("X-Amz-Date")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Date", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Security-Token")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Security-Token", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Content-Sha256", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Algorithm")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Algorithm", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Signature")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Signature", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-SignedHeaders", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Credential")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Credential", valid_601084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601086: Call_BatchDeletePhoneNumber_601074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"))
  result = hook(call_601086, url, valid)

proc call*(call_601087: Call_BatchDeletePhoneNumber_601074; body: JsonNode;
          operation: string = "batch-delete"): Recallable =
  ## batchDeletePhoneNumber
  ## <p>Moves phone numbers into the <b>Deletion queue</b>. Phone numbers must be disassociated from any users or Amazon Chime Voice Connectors before they can be deleted.</p> <p>Phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_601088 = newJObject()
  var body_601089 = newJObject()
  add(query_601088, "operation", newJString(operation))
  if body != nil:
    body_601089 = body
  result = call_601087.call(nil, query_601088, nil, nil, body_601089)

var batchDeletePhoneNumber* = Call_BatchDeletePhoneNumber_601074(
    name: "batchDeletePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-delete",
    validator: validate_BatchDeletePhoneNumber_601075, base: "/",
    url: url_BatchDeletePhoneNumber_601076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchSuspendUser_601090 = ref object of OpenApiRestCall_600426
proc url_BatchSuspendUser_601092(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_BatchSuspendUser_601091(path: JsonNode; query: JsonNode;
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
  var valid_601093 = path.getOrDefault("accountId")
  valid_601093 = validateParameter(valid_601093, JString, required = true,
                                 default = nil)
  if valid_601093 != nil:
    section.add "accountId", valid_601093
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601094 = query.getOrDefault("operation")
  valid_601094 = validateParameter(valid_601094, JString, required = true,
                                 default = newJString("suspend"))
  if valid_601094 != nil:
    section.add "operation", valid_601094
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601095 = header.getOrDefault("X-Amz-Date")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Date", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Security-Token")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Security-Token", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Content-Sha256", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Algorithm")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Algorithm", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Signature")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Signature", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-SignedHeaders", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Credential")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Credential", valid_601101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601103: Call_BatchSuspendUser_601090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ## 
  let valid = call_601103.validator(path, query, header, formData, body)
  let scheme = call_601103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601103.url(scheme.get, call_601103.host, call_601103.base,
                         call_601103.route, valid.getOrDefault("path"))
  result = hook(call_601103, url, valid)

proc call*(call_601104: Call_BatchSuspendUser_601090; accountId: string;
          body: JsonNode; operation: string = "suspend"): Recallable =
  ## batchSuspendUser
  ## <p>Suspends up to 50 users from a <code>Team</code> or <code>EnterpriseLWA</code> Amazon Chime account. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Users suspended from a <code>Team</code> account are dissasociated from the account, but they can continue to use Amazon Chime as free users. To remove the suspension from suspended <code>Team</code> account users, invite them to the <code>Team</code> account again. You can use the <a>InviteUsers</a> action to do so.</p> <p>Users suspended from an <code>EnterpriseLWA</code> account are immediately signed out of Amazon Chime and can no longer sign in. To remove the suspension from suspended <code>EnterpriseLWA</code> account users, use the <a>BatchUnsuspendUser</a> action. </p> <p>To sign out users without suspending them, use the <a>LogoutUser</a> action.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601105 = newJObject()
  var query_601106 = newJObject()
  var body_601107 = newJObject()
  add(path_601105, "accountId", newJString(accountId))
  add(query_601106, "operation", newJString(operation))
  if body != nil:
    body_601107 = body
  result = call_601104.call(path_601105, query_601106, nil, nil, body_601107)

var batchSuspendUser* = Call_BatchSuspendUser_601090(name: "batchSuspendUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=suspend",
    validator: validate_BatchSuspendUser_601091, base: "/",
    url: url_BatchSuspendUser_601092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUnsuspendUser_601108 = ref object of OpenApiRestCall_600426
proc url_BatchUnsuspendUser_601110(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_BatchUnsuspendUser_601109(path: JsonNode; query: JsonNode;
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
  var valid_601111 = path.getOrDefault("accountId")
  valid_601111 = validateParameter(valid_601111, JString, required = true,
                                 default = nil)
  if valid_601111 != nil:
    section.add "accountId", valid_601111
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601112 = query.getOrDefault("operation")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = newJString("unsuspend"))
  if valid_601112 != nil:
    section.add "operation", valid_601112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601113 = header.getOrDefault("X-Amz-Date")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Date", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Security-Token")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Security-Token", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Content-Sha256", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Algorithm")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Algorithm", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Signature")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Signature", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-SignedHeaders", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Credential")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Credential", valid_601119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601121: Call_BatchUnsuspendUser_601108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ## 
  let valid = call_601121.validator(path, query, header, formData, body)
  let scheme = call_601121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601121.url(scheme.get, call_601121.host, call_601121.base,
                         call_601121.route, valid.getOrDefault("path"))
  result = hook(call_601121, url, valid)

proc call*(call_601122: Call_BatchUnsuspendUser_601108; accountId: string;
          body: JsonNode; operation: string = "unsuspend"): Recallable =
  ## batchUnsuspendUser
  ## <p>Removes the suspension from up to 50 previously suspended users for the specified Amazon Chime <code>EnterpriseLWA</code> account. Only users on <code>EnterpriseLWA</code> accounts can be unsuspended using this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.</p> <p>Previously suspended users who are unsuspended using this action are returned to <code>Registered</code> status. Users who are not previously suspended are ignored.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601123 = newJObject()
  var query_601124 = newJObject()
  var body_601125 = newJObject()
  add(path_601123, "accountId", newJString(accountId))
  add(query_601124, "operation", newJString(operation))
  if body != nil:
    body_601125 = body
  result = call_601122.call(path_601123, query_601124, nil, nil, body_601125)

var batchUnsuspendUser* = Call_BatchUnsuspendUser_601108(
    name: "batchUnsuspendUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users#operation=unsuspend",
    validator: validate_BatchUnsuspendUser_601109, base: "/",
    url: url_BatchUnsuspendUser_601110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdatePhoneNumber_601126 = ref object of OpenApiRestCall_600426
proc url_BatchUpdatePhoneNumber_601128(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchUpdatePhoneNumber_601127(path: JsonNode; query: JsonNode;
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
  var valid_601129 = query.getOrDefault("operation")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = newJString("batch-update"))
  if valid_601129 != nil:
    section.add "operation", valid_601129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Content-Sha256", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Algorithm")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Algorithm", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Signature")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Signature", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-SignedHeaders", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Credential")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Credential", valid_601136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601138: Call_BatchUpdatePhoneNumber_601126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_601138.validator(path, query, header, formData, body)
  let scheme = call_601138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601138.url(scheme.get, call_601138.host, call_601138.base,
                         call_601138.route, valid.getOrDefault("path"))
  result = hook(call_601138, url, valid)

proc call*(call_601139: Call_BatchUpdatePhoneNumber_601126; body: JsonNode;
          operation: string = "batch-update"): Recallable =
  ## batchUpdatePhoneNumber
  ## Updates phone number product types. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   operation: string (required)
  ##   body: JObject (required)
  var query_601140 = newJObject()
  var body_601141 = newJObject()
  add(query_601140, "operation", newJString(operation))
  if body != nil:
    body_601141 = body
  result = call_601139.call(nil, query_601140, nil, nil, body_601141)

var batchUpdatePhoneNumber* = Call_BatchUpdatePhoneNumber_601126(
    name: "batchUpdatePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-numbers#operation=batch-update",
    validator: validate_BatchUpdatePhoneNumber_601127, base: "/",
    url: url_BatchUpdatePhoneNumber_601128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchUpdateUser_601162 = ref object of OpenApiRestCall_600426
proc url_BatchUpdateUser_601164(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_BatchUpdateUser_601163(path: JsonNode; query: JsonNode;
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
  var valid_601165 = path.getOrDefault("accountId")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = nil)
  if valid_601165 != nil:
    section.add "accountId", valid_601165
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
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601174: Call_BatchUpdateUser_601162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_601174.validator(path, query, header, formData, body)
  let scheme = call_601174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601174.url(scheme.get, call_601174.host, call_601174.base,
                         call_601174.route, valid.getOrDefault("path"))
  result = hook(call_601174, url, valid)

proc call*(call_601175: Call_BatchUpdateUser_601162; accountId: string;
          body: JsonNode): Recallable =
  ## batchUpdateUser
  ## Updates user details within the <a>UpdateUserRequestItem</a> object for up to 20 users for the specified Amazon Chime account. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_601176 = newJObject()
  var body_601177 = newJObject()
  add(path_601176, "accountId", newJString(accountId))
  if body != nil:
    body_601177 = body
  result = call_601175.call(path_601176, nil, nil, nil, body_601177)

var batchUpdateUser* = Call_BatchUpdateUser_601162(name: "batchUpdateUser",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users", validator: validate_BatchUpdateUser_601163,
    base: "/", url: url_BatchUpdateUser_601164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_601142 = ref object of OpenApiRestCall_600426
proc url_ListUsers_601144(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListUsers_601143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601145 = path.getOrDefault("accountId")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = nil)
  if valid_601145 != nil:
    section.add "accountId", valid_601145
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
  var valid_601146 = query.getOrDefault("user-email")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "user-email", valid_601146
  var valid_601147 = query.getOrDefault("NextToken")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "NextToken", valid_601147
  var valid_601148 = query.getOrDefault("max-results")
  valid_601148 = validateParameter(valid_601148, JInt, required = false, default = nil)
  if valid_601148 != nil:
    section.add "max-results", valid_601148
  var valid_601149 = query.getOrDefault("next-token")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "next-token", valid_601149
  var valid_601150 = query.getOrDefault("MaxResults")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "MaxResults", valid_601150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Content-Sha256", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Algorithm")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Algorithm", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Signature")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Signature", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-SignedHeaders", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Credential")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Credential", valid_601157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601158: Call_ListUsers_601142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users that belong to the specified Amazon Chime account. You can specify an email address to list only the user that the email address belongs to.
  ## 
  let valid = call_601158.validator(path, query, header, formData, body)
  let scheme = call_601158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601158.url(scheme.get, call_601158.host, call_601158.base,
                         call_601158.route, valid.getOrDefault("path"))
  result = hook(call_601158, url, valid)

proc call*(call_601159: Call_ListUsers_601142; accountId: string;
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
  var path_601160 = newJObject()
  var query_601161 = newJObject()
  add(path_601160, "accountId", newJString(accountId))
  add(query_601161, "user-email", newJString(userEmail))
  add(query_601161, "NextToken", newJString(NextToken))
  add(query_601161, "max-results", newJInt(maxResults))
  add(query_601161, "next-token", newJString(nextToken))
  add(query_601161, "MaxResults", newJString(MaxResults))
  result = call_601159.call(path_601160, query_601161, nil, nil, nil)

var listUsers* = Call_ListUsers_601142(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/users",
                                    validator: validate_ListUsers_601143,
                                    base: "/", url: url_ListUsers_601144,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAccount_601197 = ref object of OpenApiRestCall_600426
proc url_CreateAccount_601199(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAccount_601198(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601208: Call_CreateAccount_601197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_601208.validator(path, query, header, formData, body)
  let scheme = call_601208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601208.url(scheme.get, call_601208.host, call_601208.base,
                         call_601208.route, valid.getOrDefault("path"))
  result = hook(call_601208, url, valid)

proc call*(call_601209: Call_CreateAccount_601197; body: JsonNode): Recallable =
  ## createAccount
  ## Creates an Amazon Chime account under the administrator's AWS account. Only <code>Team</code> account types are currently supported for this action. For more information about different account types, see <a href="https://docs.aws.amazon.com/chime/latest/ag/manage-chime-account.html">Managing Your Amazon Chime Accounts</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   body: JObject (required)
  var body_601210 = newJObject()
  if body != nil:
    body_601210 = body
  result = call_601209.call(nil, nil, nil, nil, body_601210)

var createAccount* = Call_CreateAccount_601197(name: "createAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_CreateAccount_601198, base: "/", url: url_CreateAccount_601199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccounts_601178 = ref object of OpenApiRestCall_600426
proc url_ListAccounts_601180(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAccounts_601179(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601181 = query.getOrDefault("user-email")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "user-email", valid_601181
  var valid_601182 = query.getOrDefault("NextToken")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "NextToken", valid_601182
  var valid_601183 = query.getOrDefault("name")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "name", valid_601183
  var valid_601184 = query.getOrDefault("max-results")
  valid_601184 = validateParameter(valid_601184, JInt, required = false, default = nil)
  if valid_601184 != nil:
    section.add "max-results", valid_601184
  var valid_601185 = query.getOrDefault("next-token")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "next-token", valid_601185
  var valid_601186 = query.getOrDefault("MaxResults")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "MaxResults", valid_601186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601187 = header.getOrDefault("X-Amz-Date")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Date", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Security-Token")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Security-Token", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Content-Sha256", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Algorithm")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Algorithm", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Signature")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Signature", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-SignedHeaders", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Credential")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Credential", valid_601193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601194: Call_ListAccounts_601178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime accounts under the administrator's AWS account. You can filter accounts by account name prefix. To find out which Amazon Chime account a user belongs to, you can filter by the user's email address, which returns one account result.
  ## 
  let valid = call_601194.validator(path, query, header, formData, body)
  let scheme = call_601194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601194.url(scheme.get, call_601194.host, call_601194.base,
                         call_601194.route, valid.getOrDefault("path"))
  result = hook(call_601194, url, valid)

proc call*(call_601195: Call_ListAccounts_601178; userEmail: string = "";
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
  var query_601196 = newJObject()
  add(query_601196, "user-email", newJString(userEmail))
  add(query_601196, "NextToken", newJString(NextToken))
  add(query_601196, "name", newJString(name))
  add(query_601196, "max-results", newJInt(maxResults))
  add(query_601196, "next-token", newJString(nextToken))
  add(query_601196, "MaxResults", newJString(MaxResults))
  result = call_601195.call(nil, query_601196, nil, nil, nil)

var listAccounts* = Call_ListAccounts_601178(name: "listAccounts",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/accounts",
    validator: validate_ListAccounts_601179, base: "/", url: url_ListAccounts_601180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBot_601228 = ref object of OpenApiRestCall_600426
proc url_CreateBot_601230(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateBot_601229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601231 = path.getOrDefault("accountId")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "accountId", valid_601231
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
  var valid_601232 = header.getOrDefault("X-Amz-Date")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Date", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Security-Token")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Security-Token", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Content-Sha256", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Algorithm")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Algorithm", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Signature")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Signature", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-SignedHeaders", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Credential")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Credential", valid_601238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601240: Call_CreateBot_601228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bot for an Amazon Chime Enterprise account.
  ## 
  let valid = call_601240.validator(path, query, header, formData, body)
  let scheme = call_601240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601240.url(scheme.get, call_601240.host, call_601240.base,
                         call_601240.route, valid.getOrDefault("path"))
  result = hook(call_601240, url, valid)

proc call*(call_601241: Call_CreateBot_601228; accountId: string; body: JsonNode): Recallable =
  ## createBot
  ## Creates a bot for an Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_601242 = newJObject()
  var body_601243 = newJObject()
  add(path_601242, "accountId", newJString(accountId))
  if body != nil:
    body_601243 = body
  result = call_601241.call(path_601242, nil, nil, nil, body_601243)

var createBot* = Call_CreateBot_601228(name: "createBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com",
                                    route: "/accounts/{accountId}/bots",
                                    validator: validate_CreateBot_601229,
                                    base: "/", url: url_CreateBot_601230,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBots_601211 = ref object of OpenApiRestCall_600426
proc url_ListBots_601213(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListBots_601212(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601214 = path.getOrDefault("accountId")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = nil)
  if valid_601214 != nil:
    section.add "accountId", valid_601214
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return in a single call. Default is 10.
  ##   next-token: JString
  ##             : The token to use to retrieve the next page of results.
  section = newJObject()
  var valid_601215 = query.getOrDefault("max-results")
  valid_601215 = validateParameter(valid_601215, JInt, required = false, default = nil)
  if valid_601215 != nil:
    section.add "max-results", valid_601215
  var valid_601216 = query.getOrDefault("next-token")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "next-token", valid_601216
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601217 = header.getOrDefault("X-Amz-Date")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Date", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Security-Token")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Security-Token", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Content-Sha256", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Algorithm")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Algorithm", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Signature")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Signature", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-SignedHeaders", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Credential")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Credential", valid_601223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601224: Call_ListBots_601211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ## 
  let valid = call_601224.validator(path, query, header, formData, body)
  let scheme = call_601224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601224.url(scheme.get, call_601224.host, call_601224.base,
                         call_601224.route, valid.getOrDefault("path"))
  result = hook(call_601224, url, valid)

proc call*(call_601225: Call_ListBots_601211; accountId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBots
  ## Lists the bots associated with the administrator's Amazon Chime Enterprise account ID.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single call. Default is 10.
  ##   nextToken: string
  ##            : The token to use to retrieve the next page of results.
  var path_601226 = newJObject()
  var query_601227 = newJObject()
  add(path_601226, "accountId", newJString(accountId))
  add(query_601227, "max-results", newJInt(maxResults))
  add(query_601227, "next-token", newJString(nextToken))
  result = call_601225.call(path_601226, query_601227, nil, nil, nil)

var listBots* = Call_ListBots_601211(name: "listBots", meth: HttpMethod.HttpGet,
                                  host: "chime.amazonaws.com",
                                  route: "/accounts/{accountId}/bots",
                                  validator: validate_ListBots_601212, base: "/",
                                  url: url_ListBots_601213,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePhoneNumberOrder_601261 = ref object of OpenApiRestCall_600426
proc url_CreatePhoneNumberOrder_601263(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePhoneNumberOrder_601262(path: JsonNode; query: JsonNode;
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
  var valid_601264 = header.getOrDefault("X-Amz-Date")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Date", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Security-Token")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Security-Token", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Content-Sha256", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Algorithm")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Algorithm", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Signature")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Signature", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-SignedHeaders", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Credential")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Credential", valid_601270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601272: Call_CreatePhoneNumberOrder_601261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_601272.validator(path, query, header, formData, body)
  let scheme = call_601272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601272.url(scheme.get, call_601272.host, call_601272.base,
                         call_601272.route, valid.getOrDefault("path"))
  result = hook(call_601272, url, valid)

proc call*(call_601273: Call_CreatePhoneNumberOrder_601261; body: JsonNode): Recallable =
  ## createPhoneNumberOrder
  ## Creates an order for phone numbers to be provisioned. Choose from Amazon Chime Business Calling and Amazon Chime Voice Connector product types. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   body: JObject (required)
  var body_601274 = newJObject()
  if body != nil:
    body_601274 = body
  result = call_601273.call(nil, nil, nil, nil, body_601274)

var createPhoneNumberOrder* = Call_CreatePhoneNumberOrder_601261(
    name: "createPhoneNumberOrder", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_CreatePhoneNumberOrder_601262, base: "/",
    url: url_CreatePhoneNumberOrder_601263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumberOrders_601244 = ref object of OpenApiRestCall_600426
proc url_ListPhoneNumberOrders_601246(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPhoneNumberOrders_601245(path: JsonNode; query: JsonNode;
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
  var valid_601247 = query.getOrDefault("NextToken")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "NextToken", valid_601247
  var valid_601248 = query.getOrDefault("max-results")
  valid_601248 = validateParameter(valid_601248, JInt, required = false, default = nil)
  if valid_601248 != nil:
    section.add "max-results", valid_601248
  var valid_601249 = query.getOrDefault("next-token")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "next-token", valid_601249
  var valid_601250 = query.getOrDefault("MaxResults")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "MaxResults", valid_601250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601251 = header.getOrDefault("X-Amz-Date")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Date", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Security-Token")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Security-Token", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601258: Call_ListPhoneNumberOrders_601244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone number orders for the administrator's Amazon Chime account.
  ## 
  let valid = call_601258.validator(path, query, header, formData, body)
  let scheme = call_601258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601258.url(scheme.get, call_601258.host, call_601258.base,
                         call_601258.route, valid.getOrDefault("path"))
  result = hook(call_601258, url, valid)

proc call*(call_601259: Call_ListPhoneNumberOrders_601244; NextToken: string = "";
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
  var query_601260 = newJObject()
  add(query_601260, "NextToken", newJString(NextToken))
  add(query_601260, "max-results", newJInt(maxResults))
  add(query_601260, "next-token", newJString(nextToken))
  add(query_601260, "MaxResults", newJString(MaxResults))
  result = call_601259.call(nil, query_601260, nil, nil, nil)

var listPhoneNumberOrders* = Call_ListPhoneNumberOrders_601244(
    name: "listPhoneNumberOrders", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/phone-number-orders",
    validator: validate_ListPhoneNumberOrders_601245, base: "/",
    url: url_ListPhoneNumberOrders_601246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVoiceConnector_601292 = ref object of OpenApiRestCall_600426
proc url_CreateVoiceConnector_601294(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateVoiceConnector_601293(path: JsonNode; query: JsonNode;
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
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Content-Sha256", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Algorithm")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Algorithm", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Signature")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Signature", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-SignedHeaders", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Credential")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Credential", valid_601301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601303: Call_CreateVoiceConnector_601292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ## 
  let valid = call_601303.validator(path, query, header, formData, body)
  let scheme = call_601303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601303.url(scheme.get, call_601303.host, call_601303.base,
                         call_601303.route, valid.getOrDefault("path"))
  result = hook(call_601303, url, valid)

proc call*(call_601304: Call_CreateVoiceConnector_601292; body: JsonNode): Recallable =
  ## createVoiceConnector
  ## Creates an Amazon Chime Voice Connector under the administrator's AWS account. Enabling <a>CreateVoiceConnectorRequest$RequireEncryption</a> configures your Amazon Chime Voice Connector to use TLS transport for SIP signaling and Secure RTP (SRTP) for media. Inbound calls use TLS transport, and unencrypted outbound calls are blocked.
  ##   body: JObject (required)
  var body_601305 = newJObject()
  if body != nil:
    body_601305 = body
  result = call_601304.call(nil, nil, nil, nil, body_601305)

var createVoiceConnector* = Call_CreateVoiceConnector_601292(
    name: "createVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_CreateVoiceConnector_601293, base: "/",
    url: url_CreateVoiceConnector_601294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectors_601275 = ref object of OpenApiRestCall_600426
proc url_ListVoiceConnectors_601277(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListVoiceConnectors_601276(path: JsonNode; query: JsonNode;
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
  var valid_601278 = query.getOrDefault("NextToken")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "NextToken", valid_601278
  var valid_601279 = query.getOrDefault("max-results")
  valid_601279 = validateParameter(valid_601279, JInt, required = false, default = nil)
  if valid_601279 != nil:
    section.add "max-results", valid_601279
  var valid_601280 = query.getOrDefault("next-token")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "next-token", valid_601280
  var valid_601281 = query.getOrDefault("MaxResults")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "MaxResults", valid_601281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601282 = header.getOrDefault("X-Amz-Date")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Date", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Security-Token")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Security-Token", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Content-Sha256", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Algorithm")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Algorithm", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Signature")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Signature", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-SignedHeaders", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Credential")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Credential", valid_601288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_ListVoiceConnectors_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon Chime Voice Connectors for the administrator's AWS account.
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_ListVoiceConnectors_601275; NextToken: string = "";
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
  var query_601291 = newJObject()
  add(query_601291, "NextToken", newJString(NextToken))
  add(query_601291, "max-results", newJInt(maxResults))
  add(query_601291, "next-token", newJString(nextToken))
  add(query_601291, "MaxResults", newJString(MaxResults))
  result = call_601290.call(nil, query_601291, nil, nil, nil)

var listVoiceConnectors* = Call_ListVoiceConnectors_601275(
    name: "listVoiceConnectors", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/voice-connectors",
    validator: validate_ListVoiceConnectors_601276, base: "/",
    url: url_ListVoiceConnectors_601277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccount_601320 = ref object of OpenApiRestCall_600426
proc url_UpdateAccount_601322(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateAccount_601321(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601323 = path.getOrDefault("accountId")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = nil)
  if valid_601323 != nil:
    section.add "accountId", valid_601323
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
  var valid_601324 = header.getOrDefault("X-Amz-Date")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Date", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Security-Token")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Security-Token", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Content-Sha256", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Algorithm")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Algorithm", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Signature")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Signature", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-SignedHeaders", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Credential")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Credential", valid_601330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601332: Call_UpdateAccount_601320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ## 
  let valid = call_601332.validator(path, query, header, formData, body)
  let scheme = call_601332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601332.url(scheme.get, call_601332.host, call_601332.base,
                         call_601332.route, valid.getOrDefault("path"))
  result = hook(call_601332, url, valid)

proc call*(call_601333: Call_UpdateAccount_601320; accountId: string; body: JsonNode): Recallable =
  ## updateAccount
  ## Updates account details for the specified Amazon Chime account. Currently, only account name updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_601334 = newJObject()
  var body_601335 = newJObject()
  add(path_601334, "accountId", newJString(accountId))
  if body != nil:
    body_601335 = body
  result = call_601333.call(path_601334, nil, nil, nil, body_601335)

var updateAccount* = Call_UpdateAccount_601320(name: "updateAccount",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_UpdateAccount_601321,
    base: "/", url: url_UpdateAccount_601322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_601306 = ref object of OpenApiRestCall_600426
proc url_GetAccount_601308(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAccount_601307(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601309 = path.getOrDefault("accountId")
  valid_601309 = validateParameter(valid_601309, JString, required = true,
                                 default = nil)
  if valid_601309 != nil:
    section.add "accountId", valid_601309
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
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Content-Sha256", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Algorithm")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Algorithm", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Signature")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Signature", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-SignedHeaders", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Credential")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Credential", valid_601316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601317: Call_GetAccount_601306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ## 
  let valid = call_601317.validator(path, query, header, formData, body)
  let scheme = call_601317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601317.url(scheme.get, call_601317.host, call_601317.base,
                         call_601317.route, valid.getOrDefault("path"))
  result = hook(call_601317, url, valid)

proc call*(call_601318: Call_GetAccount_601306; accountId: string): Recallable =
  ## getAccount
  ## Retrieves details for the specified Amazon Chime account, such as account type and supported licenses.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_601319 = newJObject()
  add(path_601319, "accountId", newJString(accountId))
  result = call_601318.call(path_601319, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_601306(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "chime.amazonaws.com",
                                      route: "/accounts/{accountId}",
                                      validator: validate_GetAccount_601307,
                                      base: "/", url: url_GetAccount_601308,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccount_601336 = ref object of OpenApiRestCall_600426
proc url_DeleteAccount_601338(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "accountId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteAccount_601337(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601339 = path.getOrDefault("accountId")
  valid_601339 = validateParameter(valid_601339, JString, required = true,
                                 default = nil)
  if valid_601339 != nil:
    section.add "accountId", valid_601339
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
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Content-Sha256", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Algorithm")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Algorithm", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Signature")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Signature", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-SignedHeaders", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Credential")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Credential", valid_601346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601347: Call_DeleteAccount_601336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ## 
  let valid = call_601347.validator(path, query, header, formData, body)
  let scheme = call_601347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601347.url(scheme.get, call_601347.host, call_601347.base,
                         call_601347.route, valid.getOrDefault("path"))
  result = hook(call_601347, url, valid)

proc call*(call_601348: Call_DeleteAccount_601336; accountId: string): Recallable =
  ## deleteAccount
  ## <p>Deletes the specified Amazon Chime account. You must suspend all users before deleting a <code>Team</code> account. You can use the <a>BatchSuspendUser</a> action to do so.</p> <p>For <code>EnterpriseLWA</code> and <code>EnterpriseAD</code> accounts, you must release the claimed domains for your Amazon Chime account before deletion. As soon as you release the domain, all users under that account are suspended.</p> <p>Deleted accounts appear in your <code>Disabled</code> accounts list for 90 days. To restore a deleted account from your <code>Disabled</code> accounts list, you must contact AWS Support.</p> <p>After 90 days, deleted accounts are permanently removed from your <code>Disabled</code> accounts list.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_601349 = newJObject()
  add(path_601349, "accountId", newJString(accountId))
  result = call_601348.call(path_601349, nil, nil, nil, nil)

var deleteAccount* = Call_DeleteAccount_601336(name: "deleteAccount",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}", validator: validate_DeleteAccount_601337,
    base: "/", url: url_DeleteAccount_601338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventsConfiguration_601365 = ref object of OpenApiRestCall_600426
proc url_PutEventsConfiguration_601367(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutEventsConfiguration_601366(path: JsonNode; query: JsonNode;
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
  var valid_601368 = path.getOrDefault("accountId")
  valid_601368 = validateParameter(valid_601368, JString, required = true,
                                 default = nil)
  if valid_601368 != nil:
    section.add "accountId", valid_601368
  var valid_601369 = path.getOrDefault("botId")
  valid_601369 = validateParameter(valid_601369, JString, required = true,
                                 default = nil)
  if valid_601369 != nil:
    section.add "botId", valid_601369
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
  var valid_601370 = header.getOrDefault("X-Amz-Date")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Date", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Security-Token")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Security-Token", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Content-Sha256", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Algorithm")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Algorithm", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Signature")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Signature", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-SignedHeaders", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Credential")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Credential", valid_601376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601378: Call_PutEventsConfiguration_601365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ## 
  let valid = call_601378.validator(path, query, header, formData, body)
  let scheme = call_601378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601378.url(scheme.get, call_601378.host, call_601378.base,
                         call_601378.route, valid.getOrDefault("path"))
  result = hook(call_601378, url, valid)

proc call*(call_601379: Call_PutEventsConfiguration_601365; accountId: string;
          botId: string; body: JsonNode): Recallable =
  ## putEventsConfiguration
  ## Creates an events configuration that allows a bot to receive outgoing events sent by Amazon Chime. Choose either an HTTPS endpoint or a Lambda function ARN. For more information, see <a>Bot</a>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_601380 = newJObject()
  var body_601381 = newJObject()
  add(path_601380, "accountId", newJString(accountId))
  add(path_601380, "botId", newJString(botId))
  if body != nil:
    body_601381 = body
  result = call_601379.call(path_601380, nil, nil, nil, body_601381)

var putEventsConfiguration* = Call_PutEventsConfiguration_601365(
    name: "putEventsConfiguration", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_PutEventsConfiguration_601366, base: "/",
    url: url_PutEventsConfiguration_601367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventsConfiguration_601350 = ref object of OpenApiRestCall_600426
proc url_GetEventsConfiguration_601352(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetEventsConfiguration_601351(path: JsonNode; query: JsonNode;
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
  var valid_601353 = path.getOrDefault("accountId")
  valid_601353 = validateParameter(valid_601353, JString, required = true,
                                 default = nil)
  if valid_601353 != nil:
    section.add "accountId", valid_601353
  var valid_601354 = path.getOrDefault("botId")
  valid_601354 = validateParameter(valid_601354, JString, required = true,
                                 default = nil)
  if valid_601354 != nil:
    section.add "botId", valid_601354
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
  var valid_601355 = header.getOrDefault("X-Amz-Date")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Date", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Security-Token")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Security-Token", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Content-Sha256", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Algorithm")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Algorithm", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Signature")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Signature", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-SignedHeaders", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Credential")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Credential", valid_601361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601362: Call_GetEventsConfiguration_601350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ## 
  let valid = call_601362.validator(path, query, header, formData, body)
  let scheme = call_601362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601362.url(scheme.get, call_601362.host, call_601362.base,
                         call_601362.route, valid.getOrDefault("path"))
  result = hook(call_601362, url, valid)

proc call*(call_601363: Call_GetEventsConfiguration_601350; accountId: string;
          botId: string): Recallable =
  ## getEventsConfiguration
  ## Gets details for an events configuration that allows a bot to receive outgoing events, such as an HTTPS endpoint or Lambda function ARN. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_601364 = newJObject()
  add(path_601364, "accountId", newJString(accountId))
  add(path_601364, "botId", newJString(botId))
  result = call_601363.call(path_601364, nil, nil, nil, nil)

var getEventsConfiguration* = Call_GetEventsConfiguration_601350(
    name: "getEventsConfiguration", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_GetEventsConfiguration_601351, base: "/",
    url: url_GetEventsConfiguration_601352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventsConfiguration_601382 = ref object of OpenApiRestCall_600426
proc url_DeleteEventsConfiguration_601384(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteEventsConfiguration_601383(path: JsonNode; query: JsonNode;
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
  var valid_601385 = path.getOrDefault("accountId")
  valid_601385 = validateParameter(valid_601385, JString, required = true,
                                 default = nil)
  if valid_601385 != nil:
    section.add "accountId", valid_601385
  var valid_601386 = path.getOrDefault("botId")
  valid_601386 = validateParameter(valid_601386, JString, required = true,
                                 default = nil)
  if valid_601386 != nil:
    section.add "botId", valid_601386
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
  var valid_601387 = header.getOrDefault("X-Amz-Date")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Date", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Security-Token")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Security-Token", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Content-Sha256", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Algorithm")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Algorithm", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Signature")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Signature", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-SignedHeaders", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Credential")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Credential", valid_601393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601394: Call_DeleteEventsConfiguration_601382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"))
  result = hook(call_601394, url, valid)

proc call*(call_601395: Call_DeleteEventsConfiguration_601382; accountId: string;
          botId: string): Recallable =
  ## deleteEventsConfiguration
  ## Deletes the events configuration that allows a bot to receive outgoing events.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_601396 = newJObject()
  add(path_601396, "accountId", newJString(accountId))
  add(path_601396, "botId", newJString(botId))
  result = call_601395.call(path_601396, nil, nil, nil, nil)

var deleteEventsConfiguration* = Call_DeleteEventsConfiguration_601382(
    name: "deleteEventsConfiguration", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/bots/{botId}/events-configuration",
    validator: validate_DeleteEventsConfiguration_601383, base: "/",
    url: url_DeleteEventsConfiguration_601384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePhoneNumber_601411 = ref object of OpenApiRestCall_600426
proc url_UpdatePhoneNumber_601413(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdatePhoneNumber_601412(path: JsonNode; query: JsonNode;
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
  var valid_601414 = path.getOrDefault("phoneNumberId")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = nil)
  if valid_601414 != nil:
    section.add "phoneNumberId", valid_601414
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
  var valid_601415 = header.getOrDefault("X-Amz-Date")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Date", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Security-Token")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Security-Token", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Content-Sha256", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Algorithm")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Algorithm", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Signature")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Signature", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-SignedHeaders", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Credential")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Credential", valid_601421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601423: Call_UpdatePhoneNumber_601411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ## 
  let valid = call_601423.validator(path, query, header, formData, body)
  let scheme = call_601423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601423.url(scheme.get, call_601423.host, call_601423.base,
                         call_601423.route, valid.getOrDefault("path"))
  result = hook(call_601423, url, valid)

proc call*(call_601424: Call_UpdatePhoneNumber_601411; phoneNumberId: string;
          body: JsonNode): Recallable =
  ## updatePhoneNumber
  ## Updates phone number details, such as product type, for the specified phone number ID. For toll-free numbers, you can use only the Amazon Chime Voice Connector product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  ##   body: JObject (required)
  var path_601425 = newJObject()
  var body_601426 = newJObject()
  add(path_601425, "phoneNumberId", newJString(phoneNumberId))
  if body != nil:
    body_601426 = body
  result = call_601424.call(path_601425, nil, nil, nil, body_601426)

var updatePhoneNumber* = Call_UpdatePhoneNumber_601411(name: "updatePhoneNumber",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_UpdatePhoneNumber_601412, base: "/",
    url: url_UpdatePhoneNumber_601413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumber_601397 = ref object of OpenApiRestCall_600426
proc url_GetPhoneNumber_601399(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetPhoneNumber_601398(path: JsonNode; query: JsonNode;
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
  var valid_601400 = path.getOrDefault("phoneNumberId")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = nil)
  if valid_601400 != nil:
    section.add "phoneNumberId", valid_601400
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
  var valid_601401 = header.getOrDefault("X-Amz-Date")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Date", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Security-Token")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Security-Token", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Content-Sha256", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Algorithm")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Algorithm", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Signature")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Signature", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-SignedHeaders", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Credential")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Credential", valid_601407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601408: Call_GetPhoneNumber_601397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ## 
  let valid = call_601408.validator(path, query, header, formData, body)
  let scheme = call_601408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601408.url(scheme.get, call_601408.host, call_601408.base,
                         call_601408.route, valid.getOrDefault("path"))
  result = hook(call_601408, url, valid)

proc call*(call_601409: Call_GetPhoneNumber_601397; phoneNumberId: string): Recallable =
  ## getPhoneNumber
  ## Retrieves details for the specified phone number ID, such as associations, capabilities, and product type.
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_601410 = newJObject()
  add(path_601410, "phoneNumberId", newJString(phoneNumberId))
  result = call_601409.call(path_601410, nil, nil, nil, nil)

var getPhoneNumber* = Call_GetPhoneNumber_601397(name: "getPhoneNumber",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}", validator: validate_GetPhoneNumber_601398,
    base: "/", url: url_GetPhoneNumber_601399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePhoneNumber_601427 = ref object of OpenApiRestCall_600426
proc url_DeletePhoneNumber_601429(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "phoneNumberId" in path, "`phoneNumberId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers/"),
               (kind: VariableSegment, value: "phoneNumberId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePhoneNumber_601428(path: JsonNode; query: JsonNode;
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
  var valid_601430 = path.getOrDefault("phoneNumberId")
  valid_601430 = validateParameter(valid_601430, JString, required = true,
                                 default = nil)
  if valid_601430 != nil:
    section.add "phoneNumberId", valid_601430
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
  var valid_601431 = header.getOrDefault("X-Amz-Date")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Date", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Security-Token")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Security-Token", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Content-Sha256", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Algorithm")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Algorithm", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Signature")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Signature", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-SignedHeaders", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Credential")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Credential", valid_601437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601438: Call_DeletePhoneNumber_601427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ## 
  let valid = call_601438.validator(path, query, header, formData, body)
  let scheme = call_601438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601438.url(scheme.get, call_601438.host, call_601438.base,
                         call_601438.route, valid.getOrDefault("path"))
  result = hook(call_601438, url, valid)

proc call*(call_601439: Call_DeletePhoneNumber_601427; phoneNumberId: string): Recallable =
  ## deletePhoneNumber
  ## <p>Moves the specified phone number into the <b>Deletion queue</b>. A phone number must be disassociated from any users or Amazon Chime Voice Connectors before it can be deleted.</p> <p>Deleted phone numbers remain in the <b>Deletion queue</b> for 7 days before they are deleted permanently.</p>
  ##   phoneNumberId: string (required)
  ##                : The phone number ID.
  var path_601440 = newJObject()
  add(path_601440, "phoneNumberId", newJString(phoneNumberId))
  result = call_601439.call(path_601440, nil, nil, nil, nil)

var deletePhoneNumber* = Call_DeletePhoneNumber_601427(name: "deletePhoneNumber",
    meth: HttpMethod.HttpDelete, host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}",
    validator: validate_DeletePhoneNumber_601428, base: "/",
    url: url_DeletePhoneNumber_601429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVoiceConnector_601455 = ref object of OpenApiRestCall_600426
proc url_UpdateVoiceConnector_601457(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateVoiceConnector_601456(path: JsonNode; query: JsonNode;
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
  var valid_601458 = path.getOrDefault("voiceConnectorId")
  valid_601458 = validateParameter(valid_601458, JString, required = true,
                                 default = nil)
  if valid_601458 != nil:
    section.add "voiceConnectorId", valid_601458
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
  var valid_601459 = header.getOrDefault("X-Amz-Date")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Date", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Security-Token")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Security-Token", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Content-Sha256", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Algorithm")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Algorithm", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Signature")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Signature", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-SignedHeaders", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Credential")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Credential", valid_601465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601467: Call_UpdateVoiceConnector_601455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601467.validator(path, query, header, formData, body)
  let scheme = call_601467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601467.url(scheme.get, call_601467.host, call_601467.base,
                         call_601467.route, valid.getOrDefault("path"))
  result = hook(call_601467, url, valid)

proc call*(call_601468: Call_UpdateVoiceConnector_601455; voiceConnectorId: string;
          body: JsonNode): Recallable =
  ## updateVoiceConnector
  ## Updates details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_601469 = newJObject()
  var body_601470 = newJObject()
  add(path_601469, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_601470 = body
  result = call_601468.call(path_601469, nil, nil, nil, body_601470)

var updateVoiceConnector* = Call_UpdateVoiceConnector_601455(
    name: "updateVoiceConnector", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_UpdateVoiceConnector_601456, base: "/",
    url: url_UpdateVoiceConnector_601457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnector_601441 = ref object of OpenApiRestCall_600426
proc url_GetVoiceConnector_601443(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetVoiceConnector_601442(path: JsonNode; query: JsonNode;
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
  var valid_601444 = path.getOrDefault("voiceConnectorId")
  valid_601444 = validateParameter(valid_601444, JString, required = true,
                                 default = nil)
  if valid_601444 != nil:
    section.add "voiceConnectorId", valid_601444
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
  var valid_601445 = header.getOrDefault("X-Amz-Date")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Date", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Security-Token")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Security-Token", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Content-Sha256", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Algorithm")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Algorithm", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Signature")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Signature", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-SignedHeaders", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Credential")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Credential", valid_601451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601452: Call_GetVoiceConnector_601441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ## 
  let valid = call_601452.validator(path, query, header, formData, body)
  let scheme = call_601452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601452.url(scheme.get, call_601452.host, call_601452.base,
                         call_601452.route, valid.getOrDefault("path"))
  result = hook(call_601452, url, valid)

proc call*(call_601453: Call_GetVoiceConnector_601441; voiceConnectorId: string): Recallable =
  ## getVoiceConnector
  ## Retrieves details for the specified Amazon Chime Voice Connector, such as timestamps, name, outbound host, and encryption requirements.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601454 = newJObject()
  add(path_601454, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601453.call(path_601454, nil, nil, nil, nil)

var getVoiceConnector* = Call_GetVoiceConnector_601441(name: "getVoiceConnector",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_GetVoiceConnector_601442, base: "/",
    url: url_GetVoiceConnector_601443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnector_601471 = ref object of OpenApiRestCall_600426
proc url_DeleteVoiceConnector_601473(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVoiceConnector_601472(path: JsonNode; query: JsonNode;
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
  var valid_601474 = path.getOrDefault("voiceConnectorId")
  valid_601474 = validateParameter(valid_601474, JString, required = true,
                                 default = nil)
  if valid_601474 != nil:
    section.add "voiceConnectorId", valid_601474
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
  var valid_601475 = header.getOrDefault("X-Amz-Date")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Date", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Security-Token")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Security-Token", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Content-Sha256", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Algorithm")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Algorithm", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Signature")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Signature", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-SignedHeaders", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Credential")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Credential", valid_601481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601482: Call_DeleteVoiceConnector_601471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ## 
  let valid = call_601482.validator(path, query, header, formData, body)
  let scheme = call_601482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601482.url(scheme.get, call_601482.host, call_601482.base,
                         call_601482.route, valid.getOrDefault("path"))
  result = hook(call_601482, url, valid)

proc call*(call_601483: Call_DeleteVoiceConnector_601471; voiceConnectorId: string): Recallable =
  ## deleteVoiceConnector
  ## Deletes the specified Amazon Chime Voice Connector. Any phone numbers assigned to the Amazon Chime Voice Connector must be unassigned from it before it can be deleted.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601484 = newJObject()
  add(path_601484, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601483.call(path_601484, nil, nil, nil, nil)

var deleteVoiceConnector* = Call_DeleteVoiceConnector_601471(
    name: "deleteVoiceConnector", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}",
    validator: validate_DeleteVoiceConnector_601472, base: "/",
    url: url_DeleteVoiceConnector_601473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorOrigination_601499 = ref object of OpenApiRestCall_600426
proc url_PutVoiceConnectorOrigination_601501(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutVoiceConnectorOrigination_601500(path: JsonNode; query: JsonNode;
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
  var valid_601502 = path.getOrDefault("voiceConnectorId")
  valid_601502 = validateParameter(valid_601502, JString, required = true,
                                 default = nil)
  if valid_601502 != nil:
    section.add "voiceConnectorId", valid_601502
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
  var valid_601503 = header.getOrDefault("X-Amz-Date")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Date", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Security-Token")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Security-Token", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Content-Sha256", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Algorithm")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Algorithm", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Signature")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Signature", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-SignedHeaders", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Credential")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Credential", valid_601509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601511: Call_PutVoiceConnectorOrigination_601499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601511.validator(path, query, header, formData, body)
  let scheme = call_601511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601511.url(scheme.get, call_601511.host, call_601511.base,
                         call_601511.route, valid.getOrDefault("path"))
  result = hook(call_601511, url, valid)

proc call*(call_601512: Call_PutVoiceConnectorOrigination_601499;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorOrigination
  ## Adds origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_601513 = newJObject()
  var body_601514 = newJObject()
  add(path_601513, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_601514 = body
  result = call_601512.call(path_601513, nil, nil, nil, body_601514)

var putVoiceConnectorOrigination* = Call_PutVoiceConnectorOrigination_601499(
    name: "putVoiceConnectorOrigination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_PutVoiceConnectorOrigination_601500, base: "/",
    url: url_PutVoiceConnectorOrigination_601501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorOrigination_601485 = ref object of OpenApiRestCall_600426
proc url_GetVoiceConnectorOrigination_601487(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetVoiceConnectorOrigination_601486(path: JsonNode; query: JsonNode;
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
  var valid_601488 = path.getOrDefault("voiceConnectorId")
  valid_601488 = validateParameter(valid_601488, JString, required = true,
                                 default = nil)
  if valid_601488 != nil:
    section.add "voiceConnectorId", valid_601488
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
  var valid_601489 = header.getOrDefault("X-Amz-Date")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Date", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Security-Token")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Security-Token", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Content-Sha256", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Algorithm")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Algorithm", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Signature")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Signature", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-SignedHeaders", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Credential")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Credential", valid_601495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601496: Call_GetVoiceConnectorOrigination_601485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601496.validator(path, query, header, formData, body)
  let scheme = call_601496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601496.url(scheme.get, call_601496.host, call_601496.base,
                         call_601496.route, valid.getOrDefault("path"))
  result = hook(call_601496, url, valid)

proc call*(call_601497: Call_GetVoiceConnectorOrigination_601485;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorOrigination
  ## Retrieves origination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601498 = newJObject()
  add(path_601498, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601497.call(path_601498, nil, nil, nil, nil)

var getVoiceConnectorOrigination* = Call_GetVoiceConnectorOrigination_601485(
    name: "getVoiceConnectorOrigination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_GetVoiceConnectorOrigination_601486, base: "/",
    url: url_GetVoiceConnectorOrigination_601487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorOrigination_601515 = ref object of OpenApiRestCall_600426
proc url_DeleteVoiceConnectorOrigination_601517(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVoiceConnectorOrigination_601516(path: JsonNode;
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
  var valid_601518 = path.getOrDefault("voiceConnectorId")
  valid_601518 = validateParameter(valid_601518, JString, required = true,
                                 default = nil)
  if valid_601518 != nil:
    section.add "voiceConnectorId", valid_601518
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
  var valid_601519 = header.getOrDefault("X-Amz-Date")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Date", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Security-Token")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Security-Token", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Content-Sha256", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Algorithm")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Algorithm", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Signature")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Signature", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-SignedHeaders", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Credential")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Credential", valid_601525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601526: Call_DeleteVoiceConnectorOrigination_601515;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601526.validator(path, query, header, formData, body)
  let scheme = call_601526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601526.url(scheme.get, call_601526.host, call_601526.base,
                         call_601526.route, valid.getOrDefault("path"))
  result = hook(call_601526, url, valid)

proc call*(call_601527: Call_DeleteVoiceConnectorOrigination_601515;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorOrigination
  ## Deletes the origination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601528 = newJObject()
  add(path_601528, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601527.call(path_601528, nil, nil, nil, nil)

var deleteVoiceConnectorOrigination* = Call_DeleteVoiceConnectorOrigination_601515(
    name: "deleteVoiceConnectorOrigination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/origination",
    validator: validate_DeleteVoiceConnectorOrigination_601516, base: "/",
    url: url_DeleteVoiceConnectorOrigination_601517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTermination_601543 = ref object of OpenApiRestCall_600426
proc url_PutVoiceConnectorTermination_601545(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutVoiceConnectorTermination_601544(path: JsonNode; query: JsonNode;
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
  var valid_601546 = path.getOrDefault("voiceConnectorId")
  valid_601546 = validateParameter(valid_601546, JString, required = true,
                                 default = nil)
  if valid_601546 != nil:
    section.add "voiceConnectorId", valid_601546
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
  var valid_601547 = header.getOrDefault("X-Amz-Date")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Date", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Security-Token")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Security-Token", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Content-Sha256", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Algorithm")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Algorithm", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Signature")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Signature", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-SignedHeaders", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Credential")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Credential", valid_601553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601555: Call_PutVoiceConnectorTermination_601543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601555.validator(path, query, header, formData, body)
  let scheme = call_601555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601555.url(scheme.get, call_601555.host, call_601555.base,
                         call_601555.route, valid.getOrDefault("path"))
  result = hook(call_601555, url, valid)

proc call*(call_601556: Call_PutVoiceConnectorTermination_601543;
          voiceConnectorId: string; body: JsonNode): Recallable =
  ## putVoiceConnectorTermination
  ## Adds termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   body: JObject (required)
  var path_601557 = newJObject()
  var body_601558 = newJObject()
  add(path_601557, "voiceConnectorId", newJString(voiceConnectorId))
  if body != nil:
    body_601558 = body
  result = call_601556.call(path_601557, nil, nil, nil, body_601558)

var putVoiceConnectorTermination* = Call_PutVoiceConnectorTermination_601543(
    name: "putVoiceConnectorTermination", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_PutVoiceConnectorTermination_601544, base: "/",
    url: url_PutVoiceConnectorTermination_601545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTermination_601529 = ref object of OpenApiRestCall_600426
proc url_GetVoiceConnectorTermination_601531(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetVoiceConnectorTermination_601530(path: JsonNode; query: JsonNode;
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
  var valid_601532 = path.getOrDefault("voiceConnectorId")
  valid_601532 = validateParameter(valid_601532, JString, required = true,
                                 default = nil)
  if valid_601532 != nil:
    section.add "voiceConnectorId", valid_601532
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
  var valid_601533 = header.getOrDefault("X-Amz-Date")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Date", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Security-Token")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Security-Token", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Content-Sha256", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Algorithm")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Algorithm", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Signature")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Signature", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-SignedHeaders", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Credential")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Credential", valid_601539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601540: Call_GetVoiceConnectorTermination_601529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601540.validator(path, query, header, formData, body)
  let scheme = call_601540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601540.url(scheme.get, call_601540.host, call_601540.base,
                         call_601540.route, valid.getOrDefault("path"))
  result = hook(call_601540, url, valid)

proc call*(call_601541: Call_GetVoiceConnectorTermination_601529;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTermination
  ## Retrieves termination setting details for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601542 = newJObject()
  add(path_601542, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601541.call(path_601542, nil, nil, nil, nil)

var getVoiceConnectorTermination* = Call_GetVoiceConnectorTermination_601529(
    name: "getVoiceConnectorTermination", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_GetVoiceConnectorTermination_601530, base: "/",
    url: url_GetVoiceConnectorTermination_601531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTermination_601559 = ref object of OpenApiRestCall_600426
proc url_DeleteVoiceConnectorTermination_601561(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVoiceConnectorTermination_601560(path: JsonNode;
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
  var valid_601562 = path.getOrDefault("voiceConnectorId")
  valid_601562 = validateParameter(valid_601562, JString, required = true,
                                 default = nil)
  if valid_601562 != nil:
    section.add "voiceConnectorId", valid_601562
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
  var valid_601563 = header.getOrDefault("X-Amz-Date")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Date", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Security-Token")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Security-Token", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Content-Sha256", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Algorithm")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Algorithm", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Signature")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Signature", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-SignedHeaders", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Credential")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Credential", valid_601569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601570: Call_DeleteVoiceConnectorTermination_601559;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601570.validator(path, query, header, formData, body)
  let scheme = call_601570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601570.url(scheme.get, call_601570.host, call_601570.base,
                         call_601570.route, valid.getOrDefault("path"))
  result = hook(call_601570, url, valid)

proc call*(call_601571: Call_DeleteVoiceConnectorTermination_601559;
          voiceConnectorId: string): Recallable =
  ## deleteVoiceConnectorTermination
  ## Deletes the termination settings for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601572 = newJObject()
  add(path_601572, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601571.call(path_601572, nil, nil, nil, nil)

var deleteVoiceConnectorTermination* = Call_DeleteVoiceConnectorTermination_601559(
    name: "deleteVoiceConnectorTermination", meth: HttpMethod.HttpDelete,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination",
    validator: validate_DeleteVoiceConnectorTermination_601560, base: "/",
    url: url_DeleteVoiceConnectorTermination_601561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVoiceConnectorTerminationCredentials_601573 = ref object of OpenApiRestCall_600426
proc url_DeleteVoiceConnectorTerminationCredentials_601575(protocol: Scheme;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteVoiceConnectorTerminationCredentials_601574(path: JsonNode;
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
  var valid_601576 = path.getOrDefault("voiceConnectorId")
  valid_601576 = validateParameter(valid_601576, JString, required = true,
                                 default = nil)
  if valid_601576 != nil:
    section.add "voiceConnectorId", valid_601576
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601577 = query.getOrDefault("operation")
  valid_601577 = validateParameter(valid_601577, JString, required = true,
                                 default = newJString("delete"))
  if valid_601577 != nil:
    section.add "operation", valid_601577
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601578 = header.getOrDefault("X-Amz-Date")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Date", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Security-Token")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Security-Token", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Content-Sha256", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Algorithm")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Algorithm", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Signature")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Signature", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-SignedHeaders", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Credential")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Credential", valid_601584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601586: Call_DeleteVoiceConnectorTerminationCredentials_601573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ## 
  let valid = call_601586.validator(path, query, header, formData, body)
  let scheme = call_601586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601586.url(scheme.get, call_601586.host, call_601586.base,
                         call_601586.route, valid.getOrDefault("path"))
  result = hook(call_601586, url, valid)

proc call*(call_601587: Call_DeleteVoiceConnectorTerminationCredentials_601573;
          voiceConnectorId: string; body: JsonNode; operation: string = "delete"): Recallable =
  ## deleteVoiceConnectorTerminationCredentials
  ## Deletes the specified SIP credentials used by your equipment to authenticate during call termination.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601588 = newJObject()
  var query_601589 = newJObject()
  var body_601590 = newJObject()
  add(path_601588, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_601589, "operation", newJString(operation))
  if body != nil:
    body_601590 = body
  result = call_601587.call(path_601588, query_601589, nil, nil, body_601590)

var deleteVoiceConnectorTerminationCredentials* = Call_DeleteVoiceConnectorTerminationCredentials_601573(
    name: "deleteVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=delete",
    validator: validate_DeleteVoiceConnectorTerminationCredentials_601574,
    base: "/", url: url_DeleteVoiceConnectorTerminationCredentials_601575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumberFromUser_601591 = ref object of OpenApiRestCall_600426
proc url_DisassociatePhoneNumberFromUser_601593(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DisassociatePhoneNumberFromUser_601592(path: JsonNode;
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
  var valid_601594 = path.getOrDefault("accountId")
  valid_601594 = validateParameter(valid_601594, JString, required = true,
                                 default = nil)
  if valid_601594 != nil:
    section.add "accountId", valid_601594
  var valid_601595 = path.getOrDefault("userId")
  valid_601595 = validateParameter(valid_601595, JString, required = true,
                                 default = nil)
  if valid_601595 != nil:
    section.add "userId", valid_601595
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601596 = query.getOrDefault("operation")
  valid_601596 = validateParameter(valid_601596, JString, required = true, default = newJString(
      "disassociate-phone-number"))
  if valid_601596 != nil:
    section.add "operation", valid_601596
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601597 = header.getOrDefault("X-Amz-Date")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Date", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Security-Token")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Security-Token", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Content-Sha256", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Algorithm")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Algorithm", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Signature")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Signature", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-SignedHeaders", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Credential")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Credential", valid_601603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601604: Call_DisassociatePhoneNumberFromUser_601591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ## 
  let valid = call_601604.validator(path, query, header, formData, body)
  let scheme = call_601604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601604.url(scheme.get, call_601604.host, call_601604.base,
                         call_601604.route, valid.getOrDefault("path"))
  result = hook(call_601604, url, valid)

proc call*(call_601605: Call_DisassociatePhoneNumberFromUser_601591;
          accountId: string; userId: string;
          operation: string = "disassociate-phone-number"): Recallable =
  ## disassociatePhoneNumberFromUser
  ## Disassociates the primary provisioned phone number from the specified Amazon Chime user.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601606 = newJObject()
  var query_601607 = newJObject()
  add(path_601606, "accountId", newJString(accountId))
  add(query_601607, "operation", newJString(operation))
  add(path_601606, "userId", newJString(userId))
  result = call_601605.call(path_601606, query_601607, nil, nil, nil)

var disassociatePhoneNumberFromUser* = Call_DisassociatePhoneNumberFromUser_601591(
    name: "disassociatePhoneNumberFromUser", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=disassociate-phone-number",
    validator: validate_DisassociatePhoneNumberFromUser_601592, base: "/",
    url: url_DisassociatePhoneNumberFromUser_601593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePhoneNumbersFromVoiceConnector_601608 = ref object of OpenApiRestCall_600426
proc url_DisassociatePhoneNumbersFromVoiceConnector_601610(protocol: Scheme;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DisassociatePhoneNumbersFromVoiceConnector_601609(path: JsonNode;
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
  var valid_601611 = path.getOrDefault("voiceConnectorId")
  valid_601611 = validateParameter(valid_601611, JString, required = true,
                                 default = nil)
  if valid_601611 != nil:
    section.add "voiceConnectorId", valid_601611
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601612 = query.getOrDefault("operation")
  valid_601612 = validateParameter(valid_601612, JString, required = true, default = newJString(
      "disassociate-phone-numbers"))
  if valid_601612 != nil:
    section.add "operation", valid_601612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601613 = header.getOrDefault("X-Amz-Date")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Date", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Security-Token")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Security-Token", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Content-Sha256", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Algorithm")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Algorithm", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Signature")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Signature", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-SignedHeaders", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Credential")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Credential", valid_601619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601621: Call_DisassociatePhoneNumbersFromVoiceConnector_601608;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601621.validator(path, query, header, formData, body)
  let scheme = call_601621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601621.url(scheme.get, call_601621.host, call_601621.base,
                         call_601621.route, valid.getOrDefault("path"))
  result = hook(call_601621, url, valid)

proc call*(call_601622: Call_DisassociatePhoneNumbersFromVoiceConnector_601608;
          voiceConnectorId: string; body: JsonNode;
          operation: string = "disassociate-phone-numbers"): Recallable =
  ## disassociatePhoneNumbersFromVoiceConnector
  ## Disassociates the specified phone number from the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601623 = newJObject()
  var query_601624 = newJObject()
  var body_601625 = newJObject()
  add(path_601623, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_601624, "operation", newJString(operation))
  if body != nil:
    body_601625 = body
  result = call_601622.call(path_601623, query_601624, nil, nil, body_601625)

var disassociatePhoneNumbersFromVoiceConnector* = Call_DisassociatePhoneNumbersFromVoiceConnector_601608(
    name: "disassociatePhoneNumbersFromVoiceConnector", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}#operation=disassociate-phone-numbers",
    validator: validate_DisassociatePhoneNumbersFromVoiceConnector_601609,
    base: "/", url: url_DisassociatePhoneNumbersFromVoiceConnector_601610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAccountSettings_601640 = ref object of OpenApiRestCall_600426
proc url_UpdateAccountSettings_601642(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateAccountSettings_601641(path: JsonNode; query: JsonNode;
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
  var valid_601643 = path.getOrDefault("accountId")
  valid_601643 = validateParameter(valid_601643, JString, required = true,
                                 default = nil)
  if valid_601643 != nil:
    section.add "accountId", valid_601643
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
  var valid_601644 = header.getOrDefault("X-Amz-Date")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Date", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Security-Token")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Security-Token", valid_601645
  var valid_601646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Content-Sha256", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Algorithm")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Algorithm", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Signature")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Signature", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-SignedHeaders", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Credential")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Credential", valid_601650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601652: Call_UpdateAccountSettings_601640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_601652.validator(path, query, header, formData, body)
  let scheme = call_601652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601652.url(scheme.get, call_601652.host, call_601652.base,
                         call_601652.route, valid.getOrDefault("path"))
  result = hook(call_601652, url, valid)

proc call*(call_601653: Call_UpdateAccountSettings_601640; accountId: string;
          body: JsonNode): Recallable =
  ## updateAccountSettings
  ## Updates the settings for the specified Amazon Chime account. You can update settings for remote control of shared screens, or for the dial-out option. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  var path_601654 = newJObject()
  var body_601655 = newJObject()
  add(path_601654, "accountId", newJString(accountId))
  if body != nil:
    body_601655 = body
  result = call_601653.call(path_601654, nil, nil, nil, body_601655)

var updateAccountSettings* = Call_UpdateAccountSettings_601640(
    name: "updateAccountSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_UpdateAccountSettings_601641, base: "/",
    url: url_UpdateAccountSettings_601642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_601626 = ref object of OpenApiRestCall_600426
proc url_GetAccountSettings_601628(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAccountSettings_601627(path: JsonNode; query: JsonNode;
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
  var valid_601629 = path.getOrDefault("accountId")
  valid_601629 = validateParameter(valid_601629, JString, required = true,
                                 default = nil)
  if valid_601629 != nil:
    section.add "accountId", valid_601629
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
  var valid_601630 = header.getOrDefault("X-Amz-Date")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Date", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Security-Token")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Security-Token", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Content-Sha256", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Algorithm")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Algorithm", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Signature")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Signature", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-SignedHeaders", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Credential")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Credential", valid_601636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601637: Call_GetAccountSettings_601626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ## 
  let valid = call_601637.validator(path, query, header, formData, body)
  let scheme = call_601637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601637.url(scheme.get, call_601637.host, call_601637.base,
                         call_601637.route, valid.getOrDefault("path"))
  result = hook(call_601637, url, valid)

proc call*(call_601638: Call_GetAccountSettings_601626; accountId: string): Recallable =
  ## getAccountSettings
  ## Retrieves account settings for the specified Amazon Chime account ID, such as remote control and dial out settings. For more information about these settings, see <a href="https://docs.aws.amazon.com/chime/latest/ag/policies.html">Use the Policies Page</a> in the <i>Amazon Chime Administration Guide</i>.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  var path_601639 = newJObject()
  add(path_601639, "accountId", newJString(accountId))
  result = call_601638.call(path_601639, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_601626(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/settings",
    validator: validate_GetAccountSettings_601627, base: "/",
    url: url_GetAccountSettings_601628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBot_601671 = ref object of OpenApiRestCall_600426
proc url_UpdateBot_601673(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateBot_601672(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601674 = path.getOrDefault("accountId")
  valid_601674 = validateParameter(valid_601674, JString, required = true,
                                 default = nil)
  if valid_601674 != nil:
    section.add "accountId", valid_601674
  var valid_601675 = path.getOrDefault("botId")
  valid_601675 = validateParameter(valid_601675, JString, required = true,
                                 default = nil)
  if valid_601675 != nil:
    section.add "botId", valid_601675
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
  var valid_601676 = header.getOrDefault("X-Amz-Date")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Date", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Security-Token")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Security-Token", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Content-Sha256", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Algorithm")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Algorithm", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Signature")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Signature", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-SignedHeaders", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Credential")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Credential", valid_601682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601684: Call_UpdateBot_601671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ## 
  let valid = call_601684.validator(path, query, header, formData, body)
  let scheme = call_601684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601684.url(scheme.get, call_601684.host, call_601684.base,
                         call_601684.route, valid.getOrDefault("path"))
  result = hook(call_601684, url, valid)

proc call*(call_601685: Call_UpdateBot_601671; accountId: string; botId: string;
          body: JsonNode): Recallable =
  ## updateBot
  ## Updates the status of the specified bot, such as starting or stopping the bot from running in your Amazon Chime Enterprise account.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   body: JObject (required)
  var path_601686 = newJObject()
  var body_601687 = newJObject()
  add(path_601686, "accountId", newJString(accountId))
  add(path_601686, "botId", newJString(botId))
  if body != nil:
    body_601687 = body
  result = call_601685.call(path_601686, nil, nil, nil, body_601687)

var updateBot* = Call_UpdateBot_601671(name: "updateBot", meth: HttpMethod.HttpPost,
                                    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}",
                                    validator: validate_UpdateBot_601672,
                                    base: "/", url: url_UpdateBot_601673,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_601656 = ref object of OpenApiRestCall_600426
proc url_GetBot_601658(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBot_601657(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601659 = path.getOrDefault("accountId")
  valid_601659 = validateParameter(valid_601659, JString, required = true,
                                 default = nil)
  if valid_601659 != nil:
    section.add "accountId", valid_601659
  var valid_601660 = path.getOrDefault("botId")
  valid_601660 = validateParameter(valid_601660, JString, required = true,
                                 default = nil)
  if valid_601660 != nil:
    section.add "botId", valid_601660
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
  var valid_601661 = header.getOrDefault("X-Amz-Date")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Date", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Security-Token")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Security-Token", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Content-Sha256", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Algorithm")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Algorithm", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Signature")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Signature", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-SignedHeaders", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Credential")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Credential", valid_601667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601668: Call_GetBot_601656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ## 
  let valid = call_601668.validator(path, query, header, formData, body)
  let scheme = call_601668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601668.url(scheme.get, call_601668.host, call_601668.base,
                         call_601668.route, valid.getOrDefault("path"))
  result = hook(call_601668, url, valid)

proc call*(call_601669: Call_GetBot_601656; accountId: string; botId: string): Recallable =
  ## getBot
  ## Retrieves details for the specified bot, such as bot email address, bot type, status, and display name.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  var path_601670 = newJObject()
  add(path_601670, "accountId", newJString(accountId))
  add(path_601670, "botId", newJString(botId))
  result = call_601669.call(path_601670, nil, nil, nil, nil)

var getBot* = Call_GetBot_601656(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "chime.amazonaws.com",
                              route: "/accounts/{accountId}/bots/{botId}",
                              validator: validate_GetBot_601657, base: "/",
                              url: url_GetBot_601658,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalSettings_601700 = ref object of OpenApiRestCall_600426
proc url_UpdateGlobalSettings_601702(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGlobalSettings_601701(path: JsonNode; query: JsonNode;
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
  var valid_601703 = header.getOrDefault("X-Amz-Date")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Date", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-Security-Token")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Security-Token", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Content-Sha256", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Algorithm")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Algorithm", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Signature")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Signature", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-SignedHeaders", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Credential")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Credential", valid_601709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601711: Call_UpdateGlobalSettings_601700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_601711.validator(path, query, header, formData, body)
  let scheme = call_601711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601711.url(scheme.get, call_601711.host, call_601711.base,
                         call_601711.route, valid.getOrDefault("path"))
  result = hook(call_601711, url, valid)

proc call*(call_601712: Call_UpdateGlobalSettings_601700; body: JsonNode): Recallable =
  ## updateGlobalSettings
  ## Updates global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ##   body: JObject (required)
  var body_601713 = newJObject()
  if body != nil:
    body_601713 = body
  result = call_601712.call(nil, nil, nil, nil, body_601713)

var updateGlobalSettings* = Call_UpdateGlobalSettings_601700(
    name: "updateGlobalSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com", route: "/settings",
    validator: validate_UpdateGlobalSettings_601701, base: "/",
    url: url_UpdateGlobalSettings_601702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGlobalSettings_601688 = ref object of OpenApiRestCall_600426
proc url_GetGlobalSettings_601690(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGlobalSettings_601689(path: JsonNode; query: JsonNode;
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
  var valid_601691 = header.getOrDefault("X-Amz-Date")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Date", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Security-Token")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Security-Token", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Content-Sha256", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Algorithm")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Algorithm", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Signature")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Signature", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-SignedHeaders", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Credential")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Credential", valid_601697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601698: Call_GetGlobalSettings_601688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  ## 
  let valid = call_601698.validator(path, query, header, formData, body)
  let scheme = call_601698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601698.url(scheme.get, call_601698.host, call_601698.base,
                         call_601698.route, valid.getOrDefault("path"))
  result = hook(call_601698, url, valid)

proc call*(call_601699: Call_GetGlobalSettings_601688): Recallable =
  ## getGlobalSettings
  ## Retrieves global settings for the administrator's AWS account, such as Amazon Chime Business Calling and Amazon Chime Voice Connector settings.
  result = call_601699.call(nil, nil, nil, nil, nil)

var getGlobalSettings* = Call_GetGlobalSettings_601688(name: "getGlobalSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/settings",
    validator: validate_GetGlobalSettings_601689, base: "/",
    url: url_GetGlobalSettings_601690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPhoneNumberOrder_601714 = ref object of OpenApiRestCall_600426
proc url_GetPhoneNumberOrder_601716(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetPhoneNumberOrder_601715(path: JsonNode; query: JsonNode;
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
  var valid_601717 = path.getOrDefault("phoneNumberOrderId")
  valid_601717 = validateParameter(valid_601717, JString, required = true,
                                 default = nil)
  if valid_601717 != nil:
    section.add "phoneNumberOrderId", valid_601717
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
  var valid_601718 = header.getOrDefault("X-Amz-Date")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Date", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-Security-Token")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-Security-Token", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Content-Sha256", valid_601720
  var valid_601721 = header.getOrDefault("X-Amz-Algorithm")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Algorithm", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Signature")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Signature", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-SignedHeaders", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Credential")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Credential", valid_601724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601725: Call_GetPhoneNumberOrder_601714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ## 
  let valid = call_601725.validator(path, query, header, formData, body)
  let scheme = call_601725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601725.url(scheme.get, call_601725.host, call_601725.base,
                         call_601725.route, valid.getOrDefault("path"))
  result = hook(call_601725, url, valid)

proc call*(call_601726: Call_GetPhoneNumberOrder_601714; phoneNumberOrderId: string): Recallable =
  ## getPhoneNumberOrder
  ## Retrieves details for the specified phone number order, such as order creation timestamp, phone numbers in E.164 format, product type, and order status.
  ##   phoneNumberOrderId: string (required)
  ##                     : The ID for the phone number order.
  var path_601727 = newJObject()
  add(path_601727, "phoneNumberOrderId", newJString(phoneNumberOrderId))
  result = call_601726.call(path_601727, nil, nil, nil, nil)

var getPhoneNumberOrder* = Call_GetPhoneNumberOrder_601714(
    name: "getPhoneNumberOrder", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/phone-number-orders/{phoneNumberOrderId}",
    validator: validate_GetPhoneNumberOrder_601715, base: "/",
    url: url_GetPhoneNumberOrder_601716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_601743 = ref object of OpenApiRestCall_600426
proc url_UpdateUser_601745(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUser_601744(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601746 = path.getOrDefault("accountId")
  valid_601746 = validateParameter(valid_601746, JString, required = true,
                                 default = nil)
  if valid_601746 != nil:
    section.add "accountId", valid_601746
  var valid_601747 = path.getOrDefault("userId")
  valid_601747 = validateParameter(valid_601747, JString, required = true,
                                 default = nil)
  if valid_601747 != nil:
    section.add "userId", valid_601747
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
  var valid_601748 = header.getOrDefault("X-Amz-Date")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Date", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Security-Token")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Security-Token", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-Content-Sha256", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Algorithm")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Algorithm", valid_601751
  var valid_601752 = header.getOrDefault("X-Amz-Signature")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Signature", valid_601752
  var valid_601753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601753 = validateParameter(valid_601753, JString, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "X-Amz-SignedHeaders", valid_601753
  var valid_601754 = header.getOrDefault("X-Amz-Credential")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "X-Amz-Credential", valid_601754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601756: Call_UpdateUser_601743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ## 
  let valid = call_601756.validator(path, query, header, formData, body)
  let scheme = call_601756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601756.url(scheme.get, call_601756.host, call_601756.base,
                         call_601756.route, valid.getOrDefault("path"))
  result = hook(call_601756, url, valid)

proc call*(call_601757: Call_UpdateUser_601743; accountId: string; body: JsonNode;
          userId: string): Recallable =
  ## updateUser
  ## Updates user details for a specified user ID. Currently, only <code>LicenseType</code> updates are supported for this action.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601758 = newJObject()
  var body_601759 = newJObject()
  add(path_601758, "accountId", newJString(accountId))
  if body != nil:
    body_601759 = body
  add(path_601758, "userId", newJString(userId))
  result = call_601757.call(path_601758, nil, nil, nil, body_601759)

var updateUser* = Call_UpdateUser_601743(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}",
                                      validator: validate_UpdateUser_601744,
                                      base: "/", url: url_UpdateUser_601745,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUser_601728 = ref object of OpenApiRestCall_600426
proc url_GetUser_601730(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUser_601729(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601731 = path.getOrDefault("accountId")
  valid_601731 = validateParameter(valid_601731, JString, required = true,
                                 default = nil)
  if valid_601731 != nil:
    section.add "accountId", valid_601731
  var valid_601732 = path.getOrDefault("userId")
  valid_601732 = validateParameter(valid_601732, JString, required = true,
                                 default = nil)
  if valid_601732 != nil:
    section.add "userId", valid_601732
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
  var valid_601733 = header.getOrDefault("X-Amz-Date")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Date", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Security-Token")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Security-Token", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-Content-Sha256", valid_601735
  var valid_601736 = header.getOrDefault("X-Amz-Algorithm")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Algorithm", valid_601736
  var valid_601737 = header.getOrDefault("X-Amz-Signature")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Signature", valid_601737
  var valid_601738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-SignedHeaders", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Credential")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Credential", valid_601739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601740: Call_GetUser_601728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ## 
  let valid = call_601740.validator(path, query, header, formData, body)
  let scheme = call_601740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601740.url(scheme.get, call_601740.host, call_601740.base,
                         call_601740.route, valid.getOrDefault("path"))
  result = hook(call_601740, url, valid)

proc call*(call_601741: Call_GetUser_601728; accountId: string; userId: string): Recallable =
  ## getUser
  ## <p>Retrieves details for the specified user ID, such as primary email address, license type, and personal meeting PIN.</p> <p>To retrieve user details with an email address instead of a user ID, use the <a>ListUsers</a> action, and then filter by email address.</p>
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_601742 = newJObject()
  add(path_601742, "accountId", newJString(accountId))
  add(path_601742, "userId", newJString(userId))
  result = call_601741.call(path_601742, nil, nil, nil, nil)

var getUser* = Call_GetUser_601728(name: "getUser", meth: HttpMethod.HttpGet,
                                host: "chime.amazonaws.com",
                                route: "/accounts/{accountId}/users/{userId}",
                                validator: validate_GetUser_601729, base: "/",
                                url: url_GetUser_601730,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSettings_601775 = ref object of OpenApiRestCall_600426
proc url_UpdateUserSettings_601777(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUserSettings_601776(path: JsonNode; query: JsonNode;
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
  var valid_601778 = path.getOrDefault("accountId")
  valid_601778 = validateParameter(valid_601778, JString, required = true,
                                 default = nil)
  if valid_601778 != nil:
    section.add "accountId", valid_601778
  var valid_601779 = path.getOrDefault("userId")
  valid_601779 = validateParameter(valid_601779, JString, required = true,
                                 default = nil)
  if valid_601779 != nil:
    section.add "userId", valid_601779
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
  var valid_601780 = header.getOrDefault("X-Amz-Date")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Date", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Security-Token")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Security-Token", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-Content-Sha256", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Algorithm")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Algorithm", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-Signature")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-Signature", valid_601784
  var valid_601785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-SignedHeaders", valid_601785
  var valid_601786 = header.getOrDefault("X-Amz-Credential")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-Credential", valid_601786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601788: Call_UpdateUserSettings_601775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings for the specified user, such as phone number settings.
  ## 
  let valid = call_601788.validator(path, query, header, formData, body)
  let scheme = call_601788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601788.url(scheme.get, call_601788.host, call_601788.base,
                         call_601788.route, valid.getOrDefault("path"))
  result = hook(call_601788, url, valid)

proc call*(call_601789: Call_UpdateUserSettings_601775; accountId: string;
          body: JsonNode; userId: string): Recallable =
  ## updateUserSettings
  ## Updates the settings for the specified user, such as phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   body: JObject (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601790 = newJObject()
  var body_601791 = newJObject()
  add(path_601790, "accountId", newJString(accountId))
  if body != nil:
    body_601791 = body
  add(path_601790, "userId", newJString(userId))
  result = call_601789.call(path_601790, nil, nil, nil, body_601791)

var updateUserSettings* = Call_UpdateUserSettings_601775(
    name: "updateUserSettings", meth: HttpMethod.HttpPut,
    host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_UpdateUserSettings_601776, base: "/",
    url: url_UpdateUserSettings_601777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserSettings_601760 = ref object of OpenApiRestCall_600426
proc url_GetUserSettings_601762(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUserSettings_601761(path: JsonNode; query: JsonNode;
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
  var valid_601763 = path.getOrDefault("accountId")
  valid_601763 = validateParameter(valid_601763, JString, required = true,
                                 default = nil)
  if valid_601763 != nil:
    section.add "accountId", valid_601763
  var valid_601764 = path.getOrDefault("userId")
  valid_601764 = validateParameter(valid_601764, JString, required = true,
                                 default = nil)
  if valid_601764 != nil:
    section.add "userId", valid_601764
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
  var valid_601765 = header.getOrDefault("X-Amz-Date")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Date", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Security-Token")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Security-Token", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Content-Sha256", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-Algorithm")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Algorithm", valid_601768
  var valid_601769 = header.getOrDefault("X-Amz-Signature")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "X-Amz-Signature", valid_601769
  var valid_601770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "X-Amz-SignedHeaders", valid_601770
  var valid_601771 = header.getOrDefault("X-Amz-Credential")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-Credential", valid_601771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601772: Call_GetUserSettings_601760; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ## 
  let valid = call_601772.validator(path, query, header, formData, body)
  let scheme = call_601772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601772.url(scheme.get, call_601772.host, call_601772.base,
                         call_601772.route, valid.getOrDefault("path"))
  result = hook(call_601772, url, valid)

proc call*(call_601773: Call_GetUserSettings_601760; accountId: string;
          userId: string): Recallable =
  ## getUserSettings
  ## Retrieves settings for the specified user ID, such as any associated phone number settings.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   userId: string (required)
  ##         : The user ID.
  var path_601774 = newJObject()
  add(path_601774, "accountId", newJString(accountId))
  add(path_601774, "userId", newJString(userId))
  result = call_601773.call(path_601774, nil, nil, nil, nil)

var getUserSettings* = Call_GetUserSettings_601760(name: "getUserSettings",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}/settings",
    validator: validate_GetUserSettings_601761, base: "/", url: url_GetUserSettings_601762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVoiceConnectorTerminationHealth_601792 = ref object of OpenApiRestCall_600426
proc url_GetVoiceConnectorTerminationHealth_601794(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetVoiceConnectorTerminationHealth_601793(path: JsonNode;
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
  var valid_601795 = path.getOrDefault("voiceConnectorId")
  valid_601795 = validateParameter(valid_601795, JString, required = true,
                                 default = nil)
  if valid_601795 != nil:
    section.add "voiceConnectorId", valid_601795
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
  var valid_601796 = header.getOrDefault("X-Amz-Date")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Date", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Security-Token")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Security-Token", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Content-Sha256", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-Algorithm")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-Algorithm", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Signature")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Signature", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-SignedHeaders", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Credential")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Credential", valid_601802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601803: Call_GetVoiceConnectorTerminationHealth_601792;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601803.validator(path, query, header, formData, body)
  let scheme = call_601803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601803.url(scheme.get, call_601803.host, call_601803.base,
                         call_601803.route, valid.getOrDefault("path"))
  result = hook(call_601803, url, valid)

proc call*(call_601804: Call_GetVoiceConnectorTerminationHealth_601792;
          voiceConnectorId: string): Recallable =
  ## getVoiceConnectorTerminationHealth
  ## Retrieves information about the last time a SIP <code>OPTIONS</code> ping was received from your SIP infrastructure for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601805 = newJObject()
  add(path_601805, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601804.call(path_601805, nil, nil, nil, nil)

var getVoiceConnectorTerminationHealth* = Call_GetVoiceConnectorTerminationHealth_601792(
    name: "getVoiceConnectorTerminationHealth", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/health",
    validator: validate_GetVoiceConnectorTerminationHealth_601793, base: "/",
    url: url_GetVoiceConnectorTerminationHealth_601794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteUsers_601806 = ref object of OpenApiRestCall_600426
proc url_InviteUsers_601808(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_InviteUsers_601807(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601809 = path.getOrDefault("accountId")
  valid_601809 = validateParameter(valid_601809, JString, required = true,
                                 default = nil)
  if valid_601809 != nil:
    section.add "accountId", valid_601809
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601810 = query.getOrDefault("operation")
  valid_601810 = validateParameter(valid_601810, JString, required = true,
                                 default = newJString("add"))
  if valid_601810 != nil:
    section.add "operation", valid_601810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601811 = header.getOrDefault("X-Amz-Date")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Date", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Security-Token")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Security-Token", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Content-Sha256", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-Algorithm")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Algorithm", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Signature")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Signature", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-SignedHeaders", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-Credential")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Credential", valid_601817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601819: Call_InviteUsers_601806; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ## 
  let valid = call_601819.validator(path, query, header, formData, body)
  let scheme = call_601819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601819.url(scheme.get, call_601819.host, call_601819.base,
                         call_601819.route, valid.getOrDefault("path"))
  result = hook(call_601819, url, valid)

proc call*(call_601820: Call_InviteUsers_601806; accountId: string; body: JsonNode;
          operation: string = "add"): Recallable =
  ## inviteUsers
  ## Sends email invites to as many as 50 users, inviting them to the specified Amazon Chime <code>Team</code> account. Only <code>Team</code> account types are currently supported for this action. 
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601821 = newJObject()
  var query_601822 = newJObject()
  var body_601823 = newJObject()
  add(path_601821, "accountId", newJString(accountId))
  add(query_601822, "operation", newJString(operation))
  if body != nil:
    body_601823 = body
  result = call_601820.call(path_601821, query_601822, nil, nil, body_601823)

var inviteUsers* = Call_InviteUsers_601806(name: "inviteUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "chime.amazonaws.com", route: "/accounts/{accountId}/users#operation=add",
                                        validator: validate_InviteUsers_601807,
                                        base: "/", url: url_InviteUsers_601808,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_601824 = ref object of OpenApiRestCall_600426
proc url_ListPhoneNumbers_601826(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPhoneNumbers_601825(path: JsonNode; query: JsonNode;
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
  var valid_601827 = query.getOrDefault("filter-name")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = newJString("AccountId"))
  if valid_601827 != nil:
    section.add "filter-name", valid_601827
  var valid_601828 = query.getOrDefault("NextToken")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "NextToken", valid_601828
  var valid_601829 = query.getOrDefault("max-results")
  valid_601829 = validateParameter(valid_601829, JInt, required = false, default = nil)
  if valid_601829 != nil:
    section.add "max-results", valid_601829
  var valid_601830 = query.getOrDefault("filter-value")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "filter-value", valid_601830
  var valid_601831 = query.getOrDefault("status")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = newJString("AcquireInProgress"))
  if valid_601831 != nil:
    section.add "status", valid_601831
  var valid_601832 = query.getOrDefault("product-type")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = newJString("BusinessCalling"))
  if valid_601832 != nil:
    section.add "product-type", valid_601832
  var valid_601833 = query.getOrDefault("next-token")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "next-token", valid_601833
  var valid_601834 = query.getOrDefault("MaxResults")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "MaxResults", valid_601834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601835 = header.getOrDefault("X-Amz-Date")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Date", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Security-Token")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Security-Token", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Content-Sha256", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Algorithm")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Algorithm", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Signature")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Signature", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-SignedHeaders", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Credential")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Credential", valid_601841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601842: Call_ListPhoneNumbers_601824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the phone numbers for the specified Amazon Chime account, Amazon Chime user, or Amazon Chime Voice Connector.
  ## 
  let valid = call_601842.validator(path, query, header, formData, body)
  let scheme = call_601842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601842.url(scheme.get, call_601842.host, call_601842.base,
                         call_601842.route, valid.getOrDefault("path"))
  result = hook(call_601842, url, valid)

proc call*(call_601843: Call_ListPhoneNumbers_601824;
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
  var query_601844 = newJObject()
  add(query_601844, "filter-name", newJString(filterName))
  add(query_601844, "NextToken", newJString(NextToken))
  add(query_601844, "max-results", newJInt(maxResults))
  add(query_601844, "filter-value", newJString(filterValue))
  add(query_601844, "status", newJString(status))
  add(query_601844, "product-type", newJString(productType))
  add(query_601844, "next-token", newJString(nextToken))
  add(query_601844, "MaxResults", newJString(MaxResults))
  result = call_601843.call(nil, query_601844, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_601824(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "chime.amazonaws.com", route: "/phone-numbers",
    validator: validate_ListPhoneNumbers_601825, base: "/",
    url: url_ListPhoneNumbers_601826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVoiceConnectorTerminationCredentials_601845 = ref object of OpenApiRestCall_600426
proc url_ListVoiceConnectorTerminationCredentials_601847(protocol: Scheme;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListVoiceConnectorTerminationCredentials_601846(path: JsonNode;
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
  var valid_601848 = path.getOrDefault("voiceConnectorId")
  valid_601848 = validateParameter(valid_601848, JString, required = true,
                                 default = nil)
  if valid_601848 != nil:
    section.add "voiceConnectorId", valid_601848
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
  var valid_601849 = header.getOrDefault("X-Amz-Date")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Date", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Security-Token")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Security-Token", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Content-Sha256", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Algorithm")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Algorithm", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Signature")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Signature", valid_601853
  var valid_601854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "X-Amz-SignedHeaders", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Credential")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Credential", valid_601855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601856: Call_ListVoiceConnectorTerminationCredentials_601845;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601856.validator(path, query, header, formData, body)
  let scheme = call_601856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601856.url(scheme.get, call_601856.host, call_601856.base,
                         call_601856.route, valid.getOrDefault("path"))
  result = hook(call_601856, url, valid)

proc call*(call_601857: Call_ListVoiceConnectorTerminationCredentials_601845;
          voiceConnectorId: string): Recallable =
  ## listVoiceConnectorTerminationCredentials
  ## Lists the SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  var path_601858 = newJObject()
  add(path_601858, "voiceConnectorId", newJString(voiceConnectorId))
  result = call_601857.call(path_601858, nil, nil, nil, nil)

var listVoiceConnectorTerminationCredentials* = Call_ListVoiceConnectorTerminationCredentials_601845(
    name: "listVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com",
    route: "/voice-connectors/{voiceConnectorId}/termination/credentials",
    validator: validate_ListVoiceConnectorTerminationCredentials_601846,
    base: "/", url: url_ListVoiceConnectorTerminationCredentials_601847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LogoutUser_601859 = ref object of OpenApiRestCall_600426
proc url_LogoutUser_601861(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_LogoutUser_601860(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601862 = path.getOrDefault("accountId")
  valid_601862 = validateParameter(valid_601862, JString, required = true,
                                 default = nil)
  if valid_601862 != nil:
    section.add "accountId", valid_601862
  var valid_601863 = path.getOrDefault("userId")
  valid_601863 = validateParameter(valid_601863, JString, required = true,
                                 default = nil)
  if valid_601863 != nil:
    section.add "userId", valid_601863
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601864 = query.getOrDefault("operation")
  valid_601864 = validateParameter(valid_601864, JString, required = true,
                                 default = newJString("logout"))
  if valid_601864 != nil:
    section.add "operation", valid_601864
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601865 = header.getOrDefault("X-Amz-Date")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Date", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-Security-Token")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Security-Token", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Content-Sha256", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-Algorithm")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Algorithm", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Signature")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Signature", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-SignedHeaders", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Credential")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Credential", valid_601871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_LogoutUser_601859; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Logs out the specified user from all of the devices they are currently logged into.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"))
  result = hook(call_601872, url, valid)

proc call*(call_601873: Call_LogoutUser_601859; accountId: string; userId: string;
          operation: string = "logout"): Recallable =
  ## logoutUser
  ## Logs out the specified user from all of the devices they are currently logged into.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601874 = newJObject()
  var query_601875 = newJObject()
  add(path_601874, "accountId", newJString(accountId))
  add(query_601875, "operation", newJString(operation))
  add(path_601874, "userId", newJString(userId))
  result = call_601873.call(path_601874, query_601875, nil, nil, nil)

var logoutUser* = Call_LogoutUser_601859(name: "logoutUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "chime.amazonaws.com", route: "/accounts/{accountId}/users/{userId}#operation=logout",
                                      validator: validate_LogoutUser_601860,
                                      base: "/", url: url_LogoutUser_601861,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutVoiceConnectorTerminationCredentials_601876 = ref object of OpenApiRestCall_600426
proc url_PutVoiceConnectorTerminationCredentials_601878(protocol: Scheme;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutVoiceConnectorTerminationCredentials_601877(path: JsonNode;
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
  var valid_601879 = path.getOrDefault("voiceConnectorId")
  valid_601879 = validateParameter(valid_601879, JString, required = true,
                                 default = nil)
  if valid_601879 != nil:
    section.add "voiceConnectorId", valid_601879
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601880 = query.getOrDefault("operation")
  valid_601880 = validateParameter(valid_601880, JString, required = true,
                                 default = newJString("put"))
  if valid_601880 != nil:
    section.add "operation", valid_601880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601881 = header.getOrDefault("X-Amz-Date")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Date", valid_601881
  var valid_601882 = header.getOrDefault("X-Amz-Security-Token")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Security-Token", valid_601882
  var valid_601883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Content-Sha256", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Algorithm")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Algorithm", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Signature")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Signature", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-SignedHeaders", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Credential")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Credential", valid_601887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601889: Call_PutVoiceConnectorTerminationCredentials_601876;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ## 
  let valid = call_601889.validator(path, query, header, formData, body)
  let scheme = call_601889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601889.url(scheme.get, call_601889.host, call_601889.base,
                         call_601889.route, valid.getOrDefault("path"))
  result = hook(call_601889, url, valid)

proc call*(call_601890: Call_PutVoiceConnectorTerminationCredentials_601876;
          voiceConnectorId: string; body: JsonNode; operation: string = "put"): Recallable =
  ## putVoiceConnectorTerminationCredentials
  ## Adds termination SIP credentials for the specified Amazon Chime Voice Connector.
  ##   voiceConnectorId: string (required)
  ##                   : The Amazon Chime Voice Connector ID.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_601891 = newJObject()
  var query_601892 = newJObject()
  var body_601893 = newJObject()
  add(path_601891, "voiceConnectorId", newJString(voiceConnectorId))
  add(query_601892, "operation", newJString(operation))
  if body != nil:
    body_601893 = body
  result = call_601890.call(path_601891, query_601892, nil, nil, body_601893)

var putVoiceConnectorTerminationCredentials* = Call_PutVoiceConnectorTerminationCredentials_601876(
    name: "putVoiceConnectorTerminationCredentials", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/voice-connectors/{voiceConnectorId}/termination/credentials#operation=put",
    validator: validate_PutVoiceConnectorTerminationCredentials_601877, base: "/",
    url: url_PutVoiceConnectorTerminationCredentials_601878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegenerateSecurityToken_601894 = ref object of OpenApiRestCall_600426
proc url_RegenerateSecurityToken_601896(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RegenerateSecurityToken_601895(path: JsonNode; query: JsonNode;
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
  var valid_601897 = path.getOrDefault("accountId")
  valid_601897 = validateParameter(valid_601897, JString, required = true,
                                 default = nil)
  if valid_601897 != nil:
    section.add "accountId", valid_601897
  var valid_601898 = path.getOrDefault("botId")
  valid_601898 = validateParameter(valid_601898, JString, required = true,
                                 default = nil)
  if valid_601898 != nil:
    section.add "botId", valid_601898
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601899 = query.getOrDefault("operation")
  valid_601899 = validateParameter(valid_601899, JString, required = true, default = newJString(
      "regenerate-security-token"))
  if valid_601899 != nil:
    section.add "operation", valid_601899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601900 = header.getOrDefault("X-Amz-Date")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Date", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-Security-Token")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Security-Token", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Content-Sha256", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-Algorithm")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-Algorithm", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Signature")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Signature", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-SignedHeaders", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Credential")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Credential", valid_601906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601907: Call_RegenerateSecurityToken_601894; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Regenerates the security token for a bot.
  ## 
  let valid = call_601907.validator(path, query, header, formData, body)
  let scheme = call_601907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601907.url(scheme.get, call_601907.host, call_601907.base,
                         call_601907.route, valid.getOrDefault("path"))
  result = hook(call_601907, url, valid)

proc call*(call_601908: Call_RegenerateSecurityToken_601894; accountId: string;
          botId: string; operation: string = "regenerate-security-token"): Recallable =
  ## regenerateSecurityToken
  ## Regenerates the security token for a bot.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   botId: string (required)
  ##        : The bot ID.
  ##   operation: string (required)
  var path_601909 = newJObject()
  var query_601910 = newJObject()
  add(path_601909, "accountId", newJString(accountId))
  add(path_601909, "botId", newJString(botId))
  add(query_601910, "operation", newJString(operation))
  result = call_601908.call(path_601909, query_601910, nil, nil, nil)

var regenerateSecurityToken* = Call_RegenerateSecurityToken_601894(
    name: "regenerateSecurityToken", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com", route: "/accounts/{accountId}/bots/{botId}#operation=regenerate-security-token",
    validator: validate_RegenerateSecurityToken_601895, base: "/",
    url: url_RegenerateSecurityToken_601896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPersonalPIN_601911 = ref object of OpenApiRestCall_600426
proc url_ResetPersonalPIN_601913(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ResetPersonalPIN_601912(path: JsonNode; query: JsonNode;
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
  var valid_601914 = path.getOrDefault("accountId")
  valid_601914 = validateParameter(valid_601914, JString, required = true,
                                 default = nil)
  if valid_601914 != nil:
    section.add "accountId", valid_601914
  var valid_601915 = path.getOrDefault("userId")
  valid_601915 = validateParameter(valid_601915, JString, required = true,
                                 default = nil)
  if valid_601915 != nil:
    section.add "userId", valid_601915
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601916 = query.getOrDefault("operation")
  valid_601916 = validateParameter(valid_601916, JString, required = true,
                                 default = newJString("reset-personal-pin"))
  if valid_601916 != nil:
    section.add "operation", valid_601916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601917 = header.getOrDefault("X-Amz-Date")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Date", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-Security-Token")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-Security-Token", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Content-Sha256", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Algorithm")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Algorithm", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Signature")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Signature", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-SignedHeaders", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Credential")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Credential", valid_601923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601924: Call_ResetPersonalPIN_601911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ## 
  let valid = call_601924.validator(path, query, header, formData, body)
  let scheme = call_601924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601924.url(scheme.get, call_601924.host, call_601924.base,
                         call_601924.route, valid.getOrDefault("path"))
  result = hook(call_601924, url, valid)

proc call*(call_601925: Call_ResetPersonalPIN_601911; accountId: string;
          userId: string; operation: string = "reset-personal-pin"): Recallable =
  ## resetPersonalPIN
  ## Resets the personal meeting PIN for the specified user on an Amazon Chime account. Returns the <a>User</a> object with the updated personal meeting PIN.
  ##   accountId: string (required)
  ##            : The Amazon Chime account ID.
  ##   operation: string (required)
  ##   userId: string (required)
  ##         : The user ID.
  var path_601926 = newJObject()
  var query_601927 = newJObject()
  add(path_601926, "accountId", newJString(accountId))
  add(query_601927, "operation", newJString(operation))
  add(path_601926, "userId", newJString(userId))
  result = call_601925.call(path_601926, query_601927, nil, nil, nil)

var resetPersonalPIN* = Call_ResetPersonalPIN_601911(name: "resetPersonalPIN",
    meth: HttpMethod.HttpPost, host: "chime.amazonaws.com",
    route: "/accounts/{accountId}/users/{userId}#operation=reset-personal-pin",
    validator: validate_ResetPersonalPIN_601912, base: "/",
    url: url_ResetPersonalPIN_601913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestorePhoneNumber_601928 = ref object of OpenApiRestCall_600426
proc url_RestorePhoneNumber_601930(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RestorePhoneNumber_601929(path: JsonNode; query: JsonNode;
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
  var valid_601931 = path.getOrDefault("phoneNumberId")
  valid_601931 = validateParameter(valid_601931, JString, required = true,
                                 default = nil)
  if valid_601931 != nil:
    section.add "phoneNumberId", valid_601931
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_601932 = query.getOrDefault("operation")
  valid_601932 = validateParameter(valid_601932, JString, required = true,
                                 default = newJString("restore"))
  if valid_601932 != nil:
    section.add "operation", valid_601932
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601933 = header.getOrDefault("X-Amz-Date")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Date", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Security-Token")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Security-Token", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Content-Sha256", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Algorithm")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Algorithm", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Signature")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Signature", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-SignedHeaders", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-Credential")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-Credential", valid_601939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601940: Call_RestorePhoneNumber_601928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ## 
  let valid = call_601940.validator(path, query, header, formData, body)
  let scheme = call_601940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601940.url(scheme.get, call_601940.host, call_601940.base,
                         call_601940.route, valid.getOrDefault("path"))
  result = hook(call_601940, url, valid)

proc call*(call_601941: Call_RestorePhoneNumber_601928; phoneNumberId: string;
          operation: string = "restore"): Recallable =
  ## restorePhoneNumber
  ## Moves a phone number from the <b>Deletion queue</b> back into the phone number <b>Inventory</b>.
  ##   phoneNumberId: string (required)
  ##                : The phone number.
  ##   operation: string (required)
  var path_601942 = newJObject()
  var query_601943 = newJObject()
  add(path_601942, "phoneNumberId", newJString(phoneNumberId))
  add(query_601943, "operation", newJString(operation))
  result = call_601941.call(path_601942, query_601943, nil, nil, nil)

var restorePhoneNumber* = Call_RestorePhoneNumber_601928(
    name: "restorePhoneNumber", meth: HttpMethod.HttpPost,
    host: "chime.amazonaws.com",
    route: "/phone-numbers/{phoneNumberId}#operation=restore",
    validator: validate_RestorePhoneNumber_601929, base: "/",
    url: url_RestorePhoneNumber_601930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAvailablePhoneNumbers_601944 = ref object of OpenApiRestCall_600426
proc url_SearchAvailablePhoneNumbers_601946(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchAvailablePhoneNumbers_601945(path: JsonNode; query: JsonNode;
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
  var valid_601947 = query.getOrDefault("city")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "city", valid_601947
  var valid_601948 = query.getOrDefault("toll-free-prefix")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "toll-free-prefix", valid_601948
  var valid_601949 = query.getOrDefault("country")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "country", valid_601949
  var valid_601950 = query.getOrDefault("area-code")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "area-code", valid_601950
  assert query != nil, "query argument is necessary due to required `type` field"
  var valid_601951 = query.getOrDefault("type")
  valid_601951 = validateParameter(valid_601951, JString, required = true,
                                 default = newJString("phone-numbers"))
  if valid_601951 != nil:
    section.add "type", valid_601951
  var valid_601952 = query.getOrDefault("max-results")
  valid_601952 = validateParameter(valid_601952, JInt, required = false, default = nil)
  if valid_601952 != nil:
    section.add "max-results", valid_601952
  var valid_601953 = query.getOrDefault("next-token")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "next-token", valid_601953
  var valid_601954 = query.getOrDefault("state")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "state", valid_601954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601955 = header.getOrDefault("X-Amz-Date")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Date", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Security-Token")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Security-Token", valid_601956
  var valid_601957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Content-Sha256", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Algorithm")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Algorithm", valid_601958
  var valid_601959 = header.getOrDefault("X-Amz-Signature")
  valid_601959 = validateParameter(valid_601959, JString, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "X-Amz-Signature", valid_601959
  var valid_601960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-SignedHeaders", valid_601960
  var valid_601961 = header.getOrDefault("X-Amz-Credential")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Credential", valid_601961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601962: Call_SearchAvailablePhoneNumbers_601944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches phone numbers that can be ordered.
  ## 
  let valid = call_601962.validator(path, query, header, formData, body)
  let scheme = call_601962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601962.url(scheme.get, call_601962.host, call_601962.base,
                         call_601962.route, valid.getOrDefault("path"))
  result = hook(call_601962, url, valid)

proc call*(call_601963: Call_SearchAvailablePhoneNumbers_601944; city: string = "";
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
  var query_601964 = newJObject()
  add(query_601964, "city", newJString(city))
  add(query_601964, "toll-free-prefix", newJString(tollFreePrefix))
  add(query_601964, "country", newJString(country))
  add(query_601964, "area-code", newJString(areaCode))
  add(query_601964, "type", newJString(`type`))
  add(query_601964, "max-results", newJInt(maxResults))
  add(query_601964, "next-token", newJString(nextToken))
  add(query_601964, "state", newJString(state))
  result = call_601963.call(nil, query_601964, nil, nil, nil)

var searchAvailablePhoneNumbers* = Call_SearchAvailablePhoneNumbers_601944(
    name: "searchAvailablePhoneNumbers", meth: HttpMethod.HttpGet,
    host: "chime.amazonaws.com", route: "/search#type=phone-numbers",
    validator: validate_SearchAvailablePhoneNumbers_601945, base: "/",
    url: url_SearchAvailablePhoneNumbers_601946,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
